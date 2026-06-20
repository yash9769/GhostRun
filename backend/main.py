from fastapi import FastAPI, BackgroundTasks, HTTPException, Response, UploadFile, File, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import time
import uuid
import html
import re
import hashlib
import zipfile
import io
import json
import random
import asyncio
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser


app = FastAPI(title="GhostRun Security API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- In-memory stores ---
scans_db: Dict[str, Any] = {}
threat_reports_db: List[Dict[str, Any]] = [
    {
        "id": "t1", "title": "Phishing SMS Alert", "description": "Fake package delivery links targeting local area codes. Do not click short URLs from unknown senders.",
        "category": "phishing", "severity": "critical", "location": "San Francisco, CA",
        "lat": 37.7749, "lng": -122.4194, "timestamp": "2026-06-20T08:22:00Z",
        "upvotes": 42, "downvotes": 2, "verified": True
    },
    {
        "id": "t2", "title": "Evil Twin WiFi", "description": "Unsecured network named 'Free_SF_Public' detected near Union Square. MITM risk high.",
        "category": "wifi", "severity": "warning", "location": "Union Square, SF",
        "lat": 37.7879, "lng": -122.4075, "timestamp": "2026-06-20T07:48:00Z",
        "upvotes": 18, "downvotes": 1, "verified": True
    },
    {
        "id": "t3", "title": "Malicious QR Codes", "description": "Tampered parking meter stickers found. Leads to fraudulent payment gateway.",
        "category": "qr", "severity": "warning", "location": "The Embarcadero",
        "lat": 37.7955, "lng": -122.3937, "timestamp": "2026-06-20T06:10:00Z",
        "upvotes": 9, "downvotes": 0, "verified": False
    },
]
files_db: Dict[str, Any] = {}
ws_connections: List[WebSocket] = []

# --- Fleet mock data ---
fleet_devices = [
    {"device_id": "DEV-001", "name": "Alex's iPhone", "os": "iOS 17.4", "risk_score": 92, "status": "safe", "last_seen": "2m ago"},
    {"device_id": "DEV-002", "name": "Sarah's Android", "os": "Android 14", "risk_score": 67, "status": "warning", "last_seen": "15m ago"},
    {"device_id": "DEV-003", "name": "Marketing MacBook", "os": "macOS 14.5", "risk_score": 88, "status": "safe", "last_seen": "1h ago"},
    {"device_id": "DEV-004", "name": "Office Tablet", "os": "Android 12", "risk_score": 34, "status": "danger", "last_seen": "3h ago"},
    {"device_id": "DEV-005", "name": "John's Pixel 8", "os": "Android 14", "risk_score": 95, "status": "safe", "last_seen": "5m ago"},
]

# --- MITRE ATT&CK technique map ---
MITRE_MAP = {
    "READ_CONTACTS": {"id": "T1636.001", "tactic": "Collection", "name": "Contact List"},
    "CAMERA": {"id": "T1125", "tactic": "Collection", "name": "Video Capture"},
    "RECORD_AUDIO": {"id": "T1429", "tactic": "Collection", "name": "Audio Capture"},
    "SEND_SMS": {"id": "T1582", "tactic": "Impact", "name": "SMS Control"},
    "ACCESS_FINE_LOCATION": {"id": "T1430", "tactic": "Collection", "name": "Location Tracking"},
    "INTERNET": {"id": "T1071", "tactic": "Command and Control", "name": "C2 over HTTP"},
    "ROOT_ACCESS": {"id": "T1068", "tactic": "Privilege Escalation", "name": "Exploitation for Privilege Escalation"},
    "WRITE_EXTERNAL_STORAGE": {"id": "T1533", "tactic": "Collection", "name": "Data from Local System"},
    "SYSTEM_ALERT_WINDOW": {"id": "T1418", "tactic": "Discovery", "name": "Software Discovery"},
    "RECEIVE_BOOT_COMPLETED": {"id": "T1398", "tactic": "Persistence", "name": "Boot/Logon Autostart"},
}

# --- Models ---
class ScanRequest(BaseModel):
    user_id: str
    scan_type: str = "full"
    file_id: Optional[str] = None

class ScanVulnerability(BaseModel):
    title: str
    severity: str
    description: str
    mitre_id: Optional[str] = None
    mitre_tactic: Optional[str] = None

class ScanResult(BaseModel):
    scan_id: str
    status: str
    score: Optional[float] = None
    verdict: Optional[str] = None
    vulnerabilities: List[ScanVulnerability] = []
    behavior_summary: Optional[Dict[str, Any]] = None
    ai_summary: Optional[str] = None

class NewsItem(BaseModel):
    title: str
    content: str
    source: str
    url: str
    date: str
    image_url: Optional[str] = None

class ThreatReport(BaseModel):
    title: str
    description: str
    category: str
    severity: str
    location: str
    lat: float
    lng: float

class ArticleContent(BaseModel):
    paragraphs: List[str]

class DeviceProfile(BaseModel):
    os_version: str
    is_rooted: bool = False
    developer_mode: bool = False
    unknown_sources: bool = False
    last_os_update_days: int = 0
    sideloaded_apps: int = 0
    open_wifi_connected: bool = False

class NetworkAuditRequest(BaseModel):
    ssid: str
    bssid: Optional[str] = None
    encryption: str = "WPA2"
    signal_strength: int = -65

# --- Helper functions ---
def clean_html(text: str) -> str:
    if not text:
        return ""
    text = html.unescape(text)
    text = re.sub(r'<[^>]*>', '', text)
    return text.strip()

def format_date(pub_date_str: str) -> str:
    if not pub_date_str:
        return ""
    try:
        parts = pub_date_str.split()
        if len(parts) >= 4:
            return f"{parts[1]} {parts[2]} {parts[3]}"
    except Exception:
        pass
    return pub_date_str

def compute_risk_score_from_permissions(permissions: List[str]) -> float:
    dangerous_perms = {"READ_CONTACTS", "READ_SMS", "SEND_SMS", "RECORD_AUDIO", "CAMERA",
                       "ACCESS_FINE_LOCATION", "READ_CALL_LOG", "PROCESS_OUTGOING_CALLS",
                       "SYSTEM_ALERT_WINDOW", "RECEIVE_BOOT_COMPLETED", "WRITE_EXTERNAL_STORAGE"}
    hits = len(set(permissions) & dangerous_perms)
    base_score = 100 - (hits * 12)
    return max(10.0, min(100.0, float(base_score)))

def extract_apk_info(file_bytes: bytes, filename: str) -> Dict[str, Any]:
    """Extract info from an APK file (which is a ZIP)"""
    permissions = []
    package_name = "unknown"
    version_name = "unknown"
    version_code = "unknown"
    activities = []
    services = []
    receivers = []
    providers = []

    try:
        with zipfile.ZipFile(io.BytesIO(file_bytes), 'r') as z:
            # Try to find and parse AndroidManifest.xml
            # Note: In a real APK, the manifest is binary XML (AXML format)
            # For demo purposes, we'll detect it's an APK and return structured mock data
            names = z.namelist()
            has_manifest = "AndroidManifest.xml" in names
            has_dex = any(n.endswith('.dex') for n in names)
            
            if has_manifest and has_dex:
                # It's a real APK - parse what we can
                # Binary AXML requires special parser; return enriched mock
                permissions = ["android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE"]
                package_name = filename.replace('.apk', '').lower().replace(' ', '.')
    except Exception:
        pass

    return {
        "permissions": permissions,
        "package_name": package_name,
        "version_name": version_name,
        "version_code": version_code,
        "activities": activities,
        "services": services,
        "receivers": receivers,
        "providers": providers,
    }

async def broadcast_ws(message: dict):
    """Broadcast message to all connected WebSocket clients"""
    disconnected = []
    for ws in ws_connections:
        try:
            await ws.send_json(message)
        except Exception:
            disconnected.append(ws)
    for ws in disconnected:
        ws_connections.remove(ws)

# --- Background scan task ---
def perform_security_scan(scan_id: str, file_id: Optional[str] = None):
    time.sleep(3)
    scans_db[scan_id]["status"] = "sandbox"

    time.sleep(3)
    scans_db[scan_id]["status"] = "finding_vulnerabilities"

    time.sleep(2)

    # Use file data if available to enrich results
    file_info = files_db.get(file_id, {}) if file_id else {}
    permissions = file_info.get("permissions", [])
    score = compute_risk_score_from_permissions(permissions) if permissions else 85.0

    # Map permissions to MITRE techniques
    detected_techniques = []
    for perm in permissions:
        perm_key = perm.replace("android.permission.", "")
        if perm_key in MITRE_MAP:
            detected_techniques.append(MITRE_MAP[perm_key])

    verdict = "safe" if score >= 80 else "suspicious" if score >= 50 else "malicious"

    ai_summary = (
        f"Analysis detected {len(permissions)} permissions, {len(detected_techniques)} of which map to known MITRE ATT&CK techniques. "
        f"The application {'appears benign with standard networking permissions' if score >= 80 else 'exhibits suspicious behavior patterns consistent with data collection or exfiltration attempts'}. "
        f"Threat verdict: **{verdict.upper()}** with a security score of {score:.1f}/100."
    )

    scans_db[scan_id].update({
        "status": "completed",
        "score": score,
        "verdict": verdict,
        "ai_summary": ai_summary,
        "behavior_summary": {
            "file_access_calls": random.randint(20, 200),
            "network_connections": [
                {"host": "api.analytics.com", "ip": "104.22.14.8", "status": "monitored"},
                {"host": "cdn.updates.io", "ip": "151.101.1.57", "status": "safe"},
            ],
            "blocked_permissions_attempted": [p.replace("android.permission.", "") for p in permissions if p.replace("android.permission.", "") in {"CAMERA", "READ_CONTACTS", "RECORD_AUDIO"}],
            "mitre_techniques": detected_techniques,
        },
        "vulnerabilities": [
            ScanVulnerability(
                title="Unencrypted Network Traffic",
                severity="Medium",
                description="Detected HTTP requests without TLS encryption.",
                mitre_id="T1071",
                mitre_tactic="Command and Control"
            ),
            ScanVulnerability(
                title="Overly Broad Permissions",
                severity="Low" if score >= 70 else "High",
                description=f"Requests {len(permissions)} permissions, some may be excessive for declared functionality.",
                mitre_id="T1418",
                mitre_tactic="Discovery"
            ),
        ] if verdict != "safe" else []
    })

# --- API Routes ---

@app.get("/")
def read_root():
    return {"message": "GhostRun Security API v2.0 running", "features": 10}

# ── Scan Endpoints ──────────────────────────────────────────────────────────

@app.post("/api/scan/start")
def start_scan(request: ScanRequest, background_tasks: BackgroundTasks):
    scan_id = str(uuid.uuid4())
    new_scan = {
        "scan_id": scan_id,
        "status": "analyzing",
        "score": None,
        "verdict": None,
        "vulnerabilities": [],
        "behavior_summary": None,
        "ai_summary": None,
    }
    scans_db[scan_id] = new_scan
    background_tasks.add_task(perform_security_scan, scan_id, request.file_id)
    return new_scan

@app.get("/api/scan/{scan_id}")
def get_scan_status(scan_id: str):
    if scan_id not in scans_db:
        raise HTTPException(status_code=404, detail="Scan not found")
    return scans_db[scan_id]

# ── File Inspection Endpoints ───────────────────────────────────────────────

@app.post("/api/files/inspect")
async def inspect_file(file: UploadFile = File(...)):
    file_bytes = await file.read()
    file_id = str(uuid.uuid4())
    filename = file.filename or "unknown"
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"

    # Compute hashes
    md5 = hashlib.md5(file_bytes).hexdigest()
    sha1 = hashlib.sha1(file_bytes).hexdigest()
    sha256 = hashlib.sha256(file_bytes).hexdigest()

    # Try to extract APK info
    apk_info = {}
    if ext == "apk":
        apk_info = extract_apk_info(file_bytes, filename)
        if not apk_info["permissions"]:
            # Return realistic demo data for a demo APK
            apk_info = {
                "permissions": [
                    "android.permission.INTERNET",
                    "android.permission.ACCESS_NETWORK_STATE",
                    "android.permission.READ_CONTACTS",
                    "android.permission.WRITE_EXTERNAL_STORAGE",
                    "android.permission.CAMERA",
                    "android.permission.RECEIVE_BOOT_COMPLETED",
                    "android.permission.ACCESS_FINE_LOCATION",
                ],
                "package_name": f"com.{filename.replace('.apk', '').lower().replace(' ', '_')}.app",
                "version_name": "2.4.1",
                "version_code": "241",
                "activities": ["MainActivity", "SplashActivity", "LoginActivity"],
                "services": ["SyncService", "BackgroundTracker"],
                "receivers": ["BootReceiver", "SMSReceiver"],
                "providers": ["FileProvider"],
            }

    risk_score = compute_risk_score_from_permissions(
        [p.replace("android.permission.", "") for p in apk_info.get("permissions", [])]
    )

    file_data = {
        "file_id": file_id,
        "filename": filename,
        "file_type": ext.upper(),
        "file_size": len(file_bytes),
        "hashes": {"md5": md5, "sha1": sha1, "sha256": sha256},
        "risk_score": risk_score,
        "verdict": "safe" if risk_score >= 80 else "suspicious" if risk_score >= 50 else "malicious",
        **apk_info,
    }
    files_db[file_id] = file_data
    return file_data

@app.get("/api/files/inspect/{file_id}")
def get_file_inspection(file_id: str):
    if file_id not in files_db:
        raise HTTPException(status_code=404, detail="File not found")
    return files_db[file_id]

# ── Community Threat Endpoints ─────────────────────────────────────────────

@app.get("/api/threats")
def get_threats():
    return threat_reports_db

@app.post("/api/threats/report")
def report_threat(report: ThreatReport):
    new_report = {
        "id": str(uuid.uuid4()),
        "title": report.title,
        "description": report.description,
        "category": report.category,
        "severity": report.severity,
        "location": report.location,
        "lat": report.lat,
        "lng": report.lng,
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "upvotes": 0,
        "downvotes": 0,
        "verified": False,
    }
    threat_reports_db.append(new_report)
    return new_report

@app.post("/api/threats/{threat_id}/vote")
def vote_threat(threat_id: str, upvote: bool = True):
    for t in threat_reports_db:
        if t["id"] == threat_id:
            if upvote:
                t["upvotes"] += 1
                if t["upvotes"] >= 10:
                    t["verified"] = True
            else:
                t["downvotes"] += 1
            return t
    raise HTTPException(status_code=404, detail="Threat not found")

# ── Fleet Dashboard Endpoints ──────────────────────────────────────────────

@app.get("/api/fleet/devices")
def get_fleet_devices():
    return fleet_devices

@app.get("/api/fleet/stats")
def get_fleet_stats():
    total = len(fleet_devices)
    safe = len([d for d in fleet_devices if d["status"] == "safe"])
    warning = len([d for d in fleet_devices if d["status"] == "warning"])
    danger = len([d for d in fleet_devices if d["status"] == "danger"])
    avg_score = sum(d["risk_score"] for d in fleet_devices) / total
    return {
        "total_devices": total,
        "safe_devices": safe,
        "warning_devices": warning,
        "danger_devices": danger,
        "fleet_risk_score": round(avg_score, 1),
        "active_threat_blocks": 142,
        "policy_violations": danger,
        "wifi_violations": 3,
    }

# ── Device Score Endpoint ──────────────────────────────────────────────────

@app.post("/api/device/score")
def compute_device_score(profile: DeviceProfile):
    score = 100.0
    factors = []

    if profile.is_rooted:
        score -= 35
        factors.append({"factor": "Device Rooted", "impact": -35, "severity": "critical"})
    if profile.developer_mode:
        score -= 15
        factors.append({"factor": "Developer Mode Enabled", "impact": -15, "severity": "warning"})
    if profile.unknown_sources:
        score -= 20
        factors.append({"factor": "Unknown Sources Enabled", "impact": -20, "severity": "high"})
    if profile.last_os_update_days > 90:
        score -= 15
        factors.append({"factor": f"OS Not Updated ({profile.last_os_update_days} days)", "impact": -15, "severity": "warning"})
    elif profile.last_os_update_days > 30:
        score -= 5
        factors.append({"factor": "OS Update Pending", "impact": -5, "severity": "low"})
    if profile.sideloaded_apps > 0:
        deduction = min(20, profile.sideloaded_apps * 7)
        score -= deduction
        factors.append({"factor": f"{profile.sideloaded_apps} Sideloaded App(s)", "impact": -deduction, "severity": "high"})
    if profile.open_wifi_connected:
        score -= 10
        factors.append({"factor": "Connected to Open WiFi", "impact": -10, "severity": "warning"})

    score = max(0.0, score)
    verdict = "excellent" if score >= 90 else "good" if score >= 70 else "at_risk" if score >= 50 else "critical"

    return {
        "score": score,
        "verdict": verdict,
        "factors": factors,
        "recommendation": "Your device is well-protected." if score >= 90
            else "Address flagged items to improve your security posture.",
    }

# ── Network Audit Endpoint ─────────────────────────────────────────────────

@app.post("/api/network/audit")
def audit_network(request: NetworkAuditRequest):
    risk_factors = []
    risk_score = 100

    suspicious_ssids = ["free", "public", "open", "hotel", "airport", "starbucks", "wifi"]
    if any(s in request.ssid.lower() for s in suspicious_ssids):
        risk_score -= 30
        risk_factors.append({"flag": "Suspicious SSID Pattern", "severity": "warning",
                              "detail": "Network name matches known honeypot naming patterns."})

    if request.encryption.lower() in ["none", "open", "wep"]:
        risk_score -= 40
        risk_factors.append({"flag": "Weak or No Encryption", "severity": "critical",
                              "detail": f"Network uses {request.encryption} encryption. Traffic may be intercepted."})

    if request.signal_strength < -80:
        risk_score -= 10
        risk_factors.append({"flag": "Weak Signal", "severity": "low",
                              "detail": "Very weak signal may indicate a distant or spoofed access point."})

    verdict = "safe" if risk_score >= 80 else "suspicious" if risk_score >= 50 else "dangerous"

    return {
        "ssid": request.ssid,
        "verdict": verdict,
        "risk_score": max(0, risk_score),
        "encryption": request.encryption,
        "risk_factors": risk_factors,
        "recommendation": "Network appears safe." if verdict == "safe"
            else "Avoid transmitting sensitive data on this network." if verdict == "suspicious"
            else "Disconnect immediately. This network poses serious MITM risks.",
        "hops": [
            {"hop": 1, "host": "192.168.1.1", "label": "Gateway", "status": "monitored"},
            {"hop": 2, "host": "10.0.0.1", "label": "ISP Router", "status": "safe"},
            {"hop": 3, "host": "8.8.8.8", "label": "Google DNS", "status": "safe"},
        ]
    }

# ── AI Analysis Endpoint ───────────────────────────────────────────────────

@app.post("/api/ai/analyze")
def ai_analyze(scan_id: str):
    scan = scans_db.get(scan_id)
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")

    behavior = scan.get("behavior_summary", {}) or {}
    techniques = behavior.get("mitre_techniques", [])
    verdict = scan.get("verdict", "unknown")
    score = scan.get("score", 0)

    mitre_grid = {
        "Reconnaissance": [],
        "Resource Development": [],
        "Initial Access": [],
        "Execution": [],
        "Persistence": [],
        "Privilege Escalation": [],
        "Defense Evasion": [],
        "Credential Access": [],
        "Discovery": [],
        "Lateral Movement": [],
        "Collection": [],
        "Command and Control": [],
        "Exfiltration": [],
        "Impact": [],
    }

    for t in techniques:
        tactic = t.get("tactic", "")
        if tactic in mitre_grid:
            mitre_grid[tactic].append({"id": t["id"], "name": t["name"]})

    plain_summary = (
        f"This application was analyzed across {len(techniques)} MITRE ATT&CK techniques. "
        f"The overall threat verdict is **{verdict.upper()}** with a security score of {score:.1f}/100. "
    )
    if techniques:
        tactic_names = list(set(t["tactic"] for t in techniques))
        plain_summary += f"Key risk areas include: {', '.join(tactic_names)}. "
    plain_summary += (
        "Immediate action is recommended." if verdict in ["malicious", "suspicious"]
        else "No immediate action required."
    )

    return {
        "plain_summary": plain_summary,
        "mitre_grid": mitre_grid,
        "detected_techniques": techniques,
        "total_techniques": len(techniques),
        "verdict": verdict,
    }

# ── News Endpoints ─────────────────────────────────────────────────────────

@app.get("/api/news")
def get_news():
    feeds = [
        {"url": "https://feeds.feedburner.com/TheHackersNews", "source": "The Hacker News"},
        {"url": "https://www.wired.com/feed/category/security/latest/rss", "source": "Wired Security"}
    ]
    namespaces = {'media': 'http://search.yahoo.com/mrss/'}
    news_items = []
    for feed in feeds:
        try:
            req = urllib.request.Request(
                feed["url"],
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
            )
            with urllib.request.urlopen(req, timeout=5) as res:
                xml_data = res.read()
            root = ET.fromstring(xml_data)
            for item in root.findall('.//item'):
                title = item.find('title')
                desc = item.find('description')
                link = item.find('link')
                pub_date = item.find('pubDate')
                title_text = clean_html(title.text) if title is not None else ""
                desc_text = clean_html(desc.text) if desc is not None else ""
                link_text = link.text.strip() if (link is not None and link.text) else feed["url"]
                pub_date_raw = pub_date.text.strip() if (pub_date is not None and pub_date.text) else ""
                pub_date_formatted = format_date(pub_date_raw)
                image_url = ""
                enclosure = item.find('enclosure')
                if enclosure is not None and 'url' in enclosure.attrib:
                    image_url = enclosure.attrib['url']
                if not image_url:
                    thumbnail = item.find('media:thumbnail', namespaces)
                    if thumbnail is not None and 'url' in thumbnail.attrib:
                        image_url = thumbnail.attrib['url']
                    else:
                        for elem in item:
                            if elem.tag.endswith('thumbnail') and 'url' in elem.attrib:
                                image_url = elem.attrib['url']
                                break
                if title_text:
                    if len(desc_text) > 300:
                        desc_text = desc_text[:297] + "..."
                    news_items.append({
                        "title": title_text, "content": desc_text,
                        "source": feed["source"], "url": link_text,
                        "date": pub_date_formatted,
                        "image_url": image_url if image_url else None
                    })
        except Exception as e:
            print(f"Error fetching from {feed['source']}: {e}")

    if not news_items:
        news_items = [
            {"title": "Critical Android RCE Vulnerability Discovered", "content": "A new vulnerability allows remote code execution on affected Android devices.",
             "source": "CISA Advisory (Fallback)", "url": "https://www.cisa.gov/cybersecurity-advisories", "date": "20 Jun 2026", "image_url": None},
        ]
    return news_items

@app.get("/api/news/content")
def get_article_content(url: str):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
        with urllib.request.urlopen(req, timeout=8) as res:
            html_data = res.read().decode('utf-8', errors='ignore')

        class ParagraphExtractor(HTMLParser):
            def __init__(self):
                super().__init__()
                self.in_p = False
                self.paragraphs = []
                self.current_p = []

            def handle_starttag(self, tag, attrs):
                if tag == 'p':
                    self.in_p = True

            def handle_endtag(self, tag):
                if tag == 'p':
                    self.in_p = False
                    p_text = clean_html(''.join(self.current_p))
                    if len(p_text) > 40 and not any(term in p_text.lower() for term in ["cookie", "privacy policy", "all rights reserved", "subscribe", "newsletter"]):
                        self.paragraphs.append(p_text)
                    self.current_p = []

            def handle_data(self, data):
                if self.in_p:
                    self.current_p.append(data)

        parser = ParagraphExtractor()
        parser.feed(html_data)
        return {"paragraphs": parser.paragraphs}
    except Exception as e:
        print(f"Error scraping content from {url}: {e}")
        return {"paragraphs": []}

@app.get("/api/news/image")
def get_news_image(url: str):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
        with urllib.request.urlopen(req, timeout=10) as res:
            image_data = res.read()
            content_type = res.headers.get('Content-Type', 'image/jpeg')
        return Response(content=image_data, media_type=content_type)
    except Exception as e:
        print(f"Error proxying image {url}: {e}")
        raise HTTPException(status_code=404, detail="Image could not be retrieved")

# ── WebSocket Endpoint ─────────────────────────────────────────────────────

@app.websocket("/ws/alerts")
async def websocket_alerts(websocket: WebSocket):
    await websocket.accept()
    ws_connections.append(websocket)
    try:
        # Send welcome message
        await websocket.send_json({"type": "connected", "message": "GhostRun live alert stream connected."})
        while True:
            data = await websocket.receive_text()
            # Echo pings back
            await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        if websocket in ws_connections:
            ws_connections.remove(websocket)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)


app = FastAPI(title="GhostRun Security API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Models ---
class ScanRequest(BaseModel):
    user_id: str
    scan_type: str = "full" # full, network, app

class ScanVulnerability(BaseModel):
    title: str
    severity: str
    description: str

class ScanResult(BaseModel):
    scan_id: str
    status: str # analyzing, completed, failed
    score: Optional[int] = None
    vulnerabilities: List[ScanVulnerability] = []

class NewsItem(BaseModel):
    title: str
    content: str
    source: str
    url: str
    date: str
    image_url: Optional[str] = None

# --- Mock Database ---
scans_db = {}

# --- Background Tasks ---
def perform_security_scan(scan_id: str):
    """
    Mock function to simulate a heavy security scan.
    In reality, this would call YARA, VirusTotal, or run ML models.
    """
    # 1. Simulate Analyzing Phase
    time.sleep(3)
    scans_db[scan_id]["status"] = "sandbox"
    
    # 2. Simulate Sandbox Phase
    time.sleep(3)
    scans_db[scan_id]["status"] = "finding_vulnerabilities"
    
    # 3. Simulate results
    time.sleep(2)
    scans_db[scan_id]["status"] = "completed"
    scans_db[scan_id]["score"] = 85
    scans_db[scan_id]["vulnerabilities"] = [
        ScanVulnerability(
            title="Unencrypted Network Traffic",
            severity="Medium",
            description="Detected HTTP requests to an unknown IP without TLS."
        ),
        ScanVulnerability(
            title="Outdated Library",
            severity="Low",
            description="An embedded library is missing patches."
        )
    ]

# --- API Routes ---

@app.get("/")
def read_root():
    return {"message": "GhostRun API is running"}

@app.post("/api/scan/start", response_model=ScanResult)
def start_scan(request: ScanRequest, background_tasks: BackgroundTasks):
    scan_id = str(uuid.uuid4())
    
    new_scan = {
        "scan_id": scan_id,
        "status": "analyzing",
        "score": None,
        "vulnerabilities": []
    }
    scans_db[scan_id] = new_scan
    
    # Run the heavy scan in the background so the app doesn't freeze
    background_tasks.add_task(perform_security_scan, scan_id)
    
    return new_scan

@app.get("/api/scan/{scan_id}", response_model=ScanResult)
def get_scan_status(scan_id: str):
    if scan_id not in scans_db:
        raise HTTPException(status_code=404, detail="Scan not found")
    return scans_db[scan_id]

def clean_html(text: str) -> str:
    if not text:
        return ""
    # Unescape HTML entities
    text = html.unescape(text)
    # Remove HTML tags
    text = re.sub(r'<[^>]*>', '', text)
    # Strip whitespace
    return text.strip()

def format_date(pub_date_str: str) -> str:
    if not pub_date_str:
        return ""
    try:
        parts = pub_date_str.split()
        if len(parts) >= 4:
            return f"{parts[1]} {parts[2]} {parts[3]}"
    except Exception:
        pass
    return pub_date_str

class ArticleContent(BaseModel):
    paragraphs: List[str]

@app.get("/api/news", response_model=List[NewsItem])
def get_news():
    feeds = [
        {"url": "https://feeds.feedburner.com/TheHackersNews", "source": "The Hacker News"},
        {"url": "https://www.wired.com/feed/category/security/latest/rss", "source": "Wired Security"}
    ]
    
    namespaces = {'media': 'http://search.yahoo.com/mrss/'}
    news_items = []
    for feed in feeds:
        try:
            req = urllib.request.Request(
                feed["url"], 
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
            )
            with urllib.request.urlopen(req, timeout=5) as res:
                xml_data = res.read()
            root = ET.fromstring(xml_data)
            for item in root.findall('.//item'):
                title = item.find('title')
                desc = item.find('description')
                link = item.find('link')
                pub_date = item.find('pubDate')
                
                title_text = clean_html(title.text) if title is not None else ""
                desc_text = clean_html(desc.text) if desc is not None else ""
                link_text = link.text.strip() if (link is not None and link.text) else feed["url"]
                pub_date_raw = pub_date.text.strip() if (pub_date is not None and pub_date.text) else ""
                pub_date_formatted = format_date(pub_date_raw)
                
                # Extract image URL
                image_url = ""
                enclosure = item.find('enclosure')
                if enclosure is not None and 'url' in enclosure.attrib:
                    image_url = enclosure.attrib['url']
                
                if not image_url:
                    thumbnail = item.find('media:thumbnail', namespaces)
                    if thumbnail is not None and 'url' in thumbnail.attrib:
                        image_url = thumbnail.attrib['url']
                    else:
                        for elem in item:
                            if elem.tag.endswith('thumbnail') and 'url' in elem.attrib:
                                image_url = elem.attrib['url']
                                break
                
                if title_text:
                    if len(desc_text) > 300:
                        desc_text = desc_text[:297] + "..."
                    news_items.append(
                        NewsItem(
                            title=title_text,
                            content=desc_text,
                            source=feed["source"],
                            url=link_text,
                            date=pub_date_formatted,
                            image_url=image_url if image_url else None
                        )
                    )
        except Exception as e:
            print(f"Error fetching from {feed['source']}: {e}")
            
    if not news_items:
        news_items = [
            NewsItem(
                title="Critical Android Remote Code Execution Vulnerability Discovered",
                content="A new vulnerability allows remote attackers to execute arbitrary code on affected Android devices via a specially crafted system update transmission.",
                source="CISA Advisory (Fallback)",
                url="https://www.cisa.gov/cybersecurity-advisories",
                date="20 Jun 2026",
                image_url=None
            ),
            NewsItem(
                title="New Phishing Campaign Mimics Popular App Stores to Deliver Malware",
                content="Attackers are distributing malicious applications by creating fake app store pages that mimic genuine platforms to trick users.",
                source="CyberThreat Intel (Fallback)",
                url="https://www.cisa.gov/cybersecurity-advisories",
                date="19 Jun 2026",
                image_url=None
            )
        ]
    return news_items

@app.get("/api/news/content", response_model=ArticleContent)
def get_article_content(url: str):
    try:
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        )
        with urllib.request.urlopen(req, timeout=8) as res:
            html_data = res.read().decode('utf-8', errors='ignore')
            
        class ParagraphExtractor(HTMLParser):
            def __init__(self):
                super().__init__()
                self.in_p = False
                self.paragraphs = []
                self.current_p = []

            def handle_starttag(self, tag, attrs):
                if tag == 'p':
                    self.in_p = True

            def handle_endtag(self, tag):
                if tag == 'p':
                    self.in_p = False
                    p_text = clean_html(''.join(self.current_p))
                    # Check length and discard junk
                    if len(p_text) > 40 and not any(term in p_text.lower() for term in ["cookie", "privacy policy", "all rights reserved", "subscribe", "newsletter"]):
                        self.paragraphs.append(p_text)
                    self.current_p = []

            def handle_data(self, data):
                if self.in_p:
                    self.current_p.append(data)
                    
        parser = ParagraphExtractor()
        parser.feed(html_data)
        
        return ArticleContent(paragraphs=parser.paragraphs)
    except Exception as e:
        print(f"Error scraping content from {url}: {e}")
        return ArticleContent(paragraphs=[])

@app.get("/api/news/image")
def get_news_image(url: str):
    try:
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
        )
        with urllib.request.urlopen(req, timeout=10) as res:
            image_data = res.read()
            content_type = res.headers.get('Content-Type', 'image/jpeg')
            
        return Response(content=image_data, media_type=content_type)
    except Exception as e:
        print(f"Error proxying image {url}: {e}")
        raise HTTPException(status_code=404, detail="Image could not be retrieved")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
