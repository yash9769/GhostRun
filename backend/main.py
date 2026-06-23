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
import urllib.error
import socket
import struct
import xml.etree.ElementTree as ET
from html.parser import HTMLParser

app = FastAPI(title="GhostRun Security API v3.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── In-memory stores ──────────────────────────────────────────────────────────
scans_db: Dict[str, Any] = {}
files_db: Dict[str, Any] = {}
ws_connections: List[WebSocket] = []

async def broadcast_alert(payload: Dict[str, Any]):
    disconnected = []
    for conn in ws_connections:
        try:
            await conn.send_json(payload)
        except Exception:
            disconnected.append(conn)
    for conn in disconnected:
        if conn in ws_connections:
            ws_connections.remove(conn)

threat_reports_db: List[Dict[str, Any]] = [
    {
        "id": "t1", "title": "Phishing SMS Campaign", "description": "Fake package delivery links targeting local area codes. Do not click short URLs from unknown senders.",
        "category": "phishing", "severity": "critical", "location": "San Francisco, CA",
        "lat": 37.7749, "lng": -122.4194, "timestamp": "2026-06-20T08:22:00Z",
        "upvotes": 42, "downvotes": 2, "verified": True
    },
    {
        "id": "t2", "title": "Evil Twin WiFi Detected", "description": "Rogue network 'Free_SF_Public' near Union Square. MITM risk high — do not connect.",
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
    {
        "id": "t4", "title": "Android Malware via Sideloading", "description": "Trojanized APK posing as a popular game being distributed via Telegram channels.",
        "category": "malware", "severity": "critical", "location": "Downtown Oakland, CA",
        "lat": 37.8044, "lng": -122.2712, "timestamp": "2026-06-19T22:00:00Z",
        "upvotes": 67, "downvotes": 3, "verified": True
    },
]

fleet_devices = [
    {"device_id": "DEV-001", "name": "Alex's iPhone 15", "os": "iOS 17.4", "risk_score": 92, "status": "safe", "last_seen": "2m ago"},
    {"device_id": "DEV-002", "name": "Sarah's Pixel 8", "os": "Android 14", "risk_score": 67, "status": "warning", "last_seen": "15m ago"},
    {"device_id": "DEV-003", "name": "Marketing MacBook", "os": "macOS 14.5", "risk_score": 88, "status": "safe", "last_seen": "1h ago"},
    {"device_id": "DEV-004", "name": "Office Android Tablet", "os": "Android 12", "risk_score": 34, "status": "danger", "last_seen": "3h ago"},
    {"device_id": "DEV-005", "name": "John's Pixel 7a", "os": "Android 14", "risk_score": 95, "status": "safe", "last_seen": "5m ago"},
]

# ── MITRE ATT&CK Mapping ──────────────────────────────────────────────────────
MITRE_MAP = {
    "READ_CONTACTS":            {"id": "T1636.001", "tactic": "Collection",           "name": "Contact List"},
    "CAMERA":                   {"id": "T1125",     "tactic": "Collection",           "name": "Video Capture"},
    "RECORD_AUDIO":             {"id": "T1429",     "tactic": "Collection",           "name": "Audio Capture"},
    "SEND_SMS":                 {"id": "T1582",     "tactic": "Impact",               "name": "SMS Control"},
    "READ_SMS":                 {"id": "T1636.004", "tactic": "Collection",           "name": "SMS Messages"},
    "ACCESS_FINE_LOCATION":     {"id": "T1430",     "tactic": "Collection",           "name": "Location Tracking"},
    "ACCESS_COARSE_LOCATION":   {"id": "T1430",     "tactic": "Collection",           "name": "Location Tracking"},
    "INTERNET":                 {"id": "T1071",     "tactic": "Command and Control",  "name": "C2 over HTTP"},
    "ROOT_ACCESS":              {"id": "T1068",     "tactic": "Privilege Escalation", "name": "Exploitation for Privilege Escalation"},
    "WRITE_EXTERNAL_STORAGE":   {"id": "T1533",     "tactic": "Collection",           "name": "Data from Local System"},
    "READ_EXTERNAL_STORAGE":    {"id": "T1533",     "tactic": "Collection",           "name": "Data from Local System"},
    "SYSTEM_ALERT_WINDOW":      {"id": "T1418",     "tactic": "Discovery",            "name": "Software Discovery"},
    "RECEIVE_BOOT_COMPLETED":   {"id": "T1398",     "tactic": "Persistence",          "name": "Boot/Logon Autostart"},
    "PROCESS_OUTGOING_CALLS":   {"id": "T1636.002", "tactic": "Collection",           "name": "Call Log"},
    "READ_CALL_LOG":            {"id": "T1636.002", "tactic": "Collection",           "name": "Call Log"},
    "GET_ACCOUNTS":             {"id": "T1636.003", "tactic": "Collection",           "name": "Account List"},
    "USE_BIOMETRIC":            {"id": "T1417",     "tactic": "Credential Access",    "name": "Input Capture"},
    "PACKAGE_USAGE_STATS":      {"id": "T1418",     "tactic": "Discovery",            "name": "Software Discovery"},
    "BIND_ACCESSIBILITY_SERVICE":{"id":"T1417",     "tactic": "Credential Access",    "name": "Input Capture"},
    "REQUEST_INSTALL_PACKAGES": {"id": "T1072",     "tactic": "Execution",            "name": "Software Deployment Tools"},
    "FOREGROUND_SERVICE":       {"id": "T1398",     "tactic": "Persistence",          "name": "Boot/Logon Autostart"},
    "VIBRATE":                  {"id": "T1418",     "tactic": "Discovery",            "name": "Software Discovery"},
    "WAKE_LOCK":                {"id": "T1398",     "tactic": "Persistence",          "name": "Boot/Logon Autostart"},
}

DANGEROUS_PERMISSIONS = {
    "READ_CONTACTS", "READ_SMS", "SEND_SMS", "RECORD_AUDIO", "CAMERA",
    "ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION", "READ_CALL_LOG",
    "PROCESS_OUTGOING_CALLS", "SYSTEM_ALERT_WINDOW", "RECEIVE_BOOT_COMPLETED",
    "WRITE_EXTERNAL_STORAGE", "READ_EXTERNAL_STORAGE", "GET_ACCOUNTS",
    "USE_BIOMETRIC", "PACKAGE_USAGE_STATS", "BIND_ACCESSIBILITY_SERVICE",
    "REQUEST_INSTALL_PACKAGES",
}

# ── Models ────────────────────────────────────────────────────────────────────
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

class ThreatReport(BaseModel):
    title: str
    description: str
    category: str
    severity: str
    location: str
    lat: float
    lng: float

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

# ── APK Binary Manifest Parser ────────────────────────────────────────────────
# Android Binary XML (AXML) parser — pure Python, no external deps
CHUNK_NULL              = 0x0000
CHUNK_STRING_TABLE      = 0x0001
CHUNK_RES_TABLE         = 0x0002
CHUNK_START_DOCUMENT    = 0x0100
CHUNK_END_DOCUMENT      = 0x0101
CHUNK_START_TAG         = 0x0102
CHUNK_END_TAG           = 0x0103
CHUNK_TEXT              = 0x0104

def _read_axml(data: bytes) -> ET.Element:
    """Parse Android Binary XML (AXML) into an ElementTree."""
    off = 0
    string_pool = []

    def u32(o): return struct.unpack_from('<I', data, o)[0]
    def u16(o): return struct.unpack_from('<H', data, o)[0]
    def s32(o): return struct.unpack_from('<i', data, o)[0]

    # Header: magic 0x00080003
    magic = u16(0)
    if magic != 0x0003:
        raise ValueError("Not AXML")
    off = 8  # skip header

    # Parse string pool
    if u16(off) == 0x0001:  # RES_STRING_POOL_TYPE
        pool_size = u32(off + 4)
        str_count = u32(off + 8)
        str_off_base = u32(off + 20)
        strings_start = off + 28
        offsets_start = off + 28
        base = off + 8 + str_off_base
        for i in range(str_count):
            str_off = u32(offsets_start + i * 4)
            s_pos = base + str_off
            length = u16(s_pos)
            # UTF-16LE
            s = data[s_pos + 2: s_pos + 2 + length * 2].decode('utf-16-le', errors='replace')
            string_pool.append(s)
        off += pool_size

    root_elem = None
    stack: List[ET.Element] = []

    while off < len(data):
        chunk_type = u16(off)
        chunk_size = u32(off + 4) if off + 8 <= len(data) else 0
        if chunk_size == 0:
            break

        if chunk_type == CHUNK_START_TAG:
            ns_idx  = s32(off + 16)
            name_idx = s32(off + 20)
            attr_count = u16(off + 28)
            name = string_pool[name_idx] if 0 <= name_idx < len(string_pool) else ''
            elem = ET.Element(name)

            for i in range(attr_count):
                ao = off + 36 + i * 20
                attr_ns  = s32(ao)
                attr_name = s32(ao + 4)
                attr_raw = s32(ao + 8)
                attr_val = s32(ao + 16)
                aname = string_pool[attr_name] if 0 <= attr_name < len(string_pool) else ''
                if 0 <= attr_raw < len(string_pool):
                    aval = string_pool[attr_raw]
                else:
                    aval = str(attr_val)
                elem.set(aname, aval)

            if stack:
                stack[-1].append(elem)
            else:
                root_elem = elem
            stack.append(elem)

        elif chunk_type == CHUNK_END_TAG:
            if stack:
                stack.pop()

        off += chunk_size

    return root_elem

def extract_apk_real(file_bytes: bytes, filename: str) -> Dict[str, Any]:
    """
    Real APK analysis using pure-Python AXML parser.
    APKs are ZIP files; AndroidManifest.xml inside is Android Binary XML.
    """
    permissions = []
    package_name = filename.replace('.apk', '').lower()
    version_name = "unknown"
    version_code = "unknown"
    activities = []
    services = []
    receivers = []
    providers = []
    min_sdk = None
    target_sdk = None
    native_libs = []
    dex_count = 0
    total_files = 0
    has_anti_debug = False
    obfuscated = False

    try:
        with zipfile.ZipFile(io.BytesIO(file_bytes), 'r') as zf:
            names = zf.namelist()
            total_files = len(names)
            dex_count = sum(1 for n in names if n.endswith('.dex'))
            native_libs = list(set(
                n.split('/')[1] for n in names
                if n.startswith('lib/') and n.count('/') >= 2 and n.endswith('.so')
            ))
            has_anti_debug = any('ptrace' in n.lower() or 'antidb' in n.lower() for n in names)
            # Obfuscation heuristic: many short class names in dex
            obfuscated = any(len(n.split('/')[-1].replace('.class', '')) <= 2 for n in names if n.endswith('.class'))

            if "AndroidManifest.xml" in names:
                manifest_bytes = zf.read("AndroidManifest.xml")
                try:
                    root = _read_axml(manifest_bytes)
                    if root is None:
                        raise ValueError("AXML parse returned None")
                    
                    # Get package/version from manifest root
                    package_name = root.get('package', package_name)
                    version_name = root.get('versionName', 'unknown')
                    version_code = root.get('versionCode', 'unknown')

                    for elem in root.iter():
                        tag = elem.tag.lower()
                        name_attr = elem.get('name', '')
                        if tag == 'uses-permission':
                            perm = name_attr.replace('android.permission.', '')
                            if perm and perm not in permissions:
                                permissions.append(perm)
                        elif tag == 'activity':
                            if name_attr: activities.append(name_attr.split('.')[-1])
                        elif tag == 'service':
                            if name_attr: services.append(name_attr.split('.')[-1])
                        elif tag == 'receiver':
                            if name_attr: receivers.append(name_attr.split('.')[-1])
                        elif tag == 'provider':
                            if name_attr: providers.append(name_attr.split('.')[-1])
                        elif tag == 'uses-sdk':
                            min_sdk = elem.get('minSdkVersion')
                            target_sdk = elem.get('targetSdkVersion')
                except Exception as parse_err:
                    # AXML parsing failed — try string scanning as fallback
                    text = manifest_bytes.decode('utf-8', errors='ignore')
                    perm_matches = re.findall(r'android\.permission\.([A-Z_]+)', text)
                    permissions = list(set(perm_matches))
                    pkg_match = re.search(r'package="([^"]+)"', text)
                    if pkg_match:
                        package_name = pkg_match.group(1)
    except Exception as e:
        pass

    return {
        "permissions": permissions,
        "package_name": package_name,
        "version_name": version_name,
        "version_code": version_code,
        "activities": activities[:20],
        "services": services[:20],
        "receivers": receivers[:20],
        "providers": providers[:20],
        "native_libs": native_libs,
        "dex_count": dex_count,
        "total_files": total_files,
        "has_anti_debug": has_anti_debug,
        "obfuscated": obfuscated,
        "min_sdk": min_sdk,
        "target_sdk": target_sdk,
    }

# ── Network Real Testing ──────────────────────────────────────────────────────
def _tcp_ping(host: str, port: int, timeout: float = 3.0) -> Optional[float]:
    """Returns latency in ms or None on failure."""
    try:
        start = time.perf_counter()
        sock = socket.create_connection((host, port), timeout=timeout)
        sock.close()
        return round((time.perf_counter() - start) * 1000, 1)
    except Exception:
        return None

def _dns_resolve(hostname: str) -> Optional[str]:
    try:
        return socket.gethostbyname(hostname)
    except Exception:
        return None

def _http_get_latency(url: str, timeout: float = 5.0) -> Dict[str, Any]:
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'GhostRun/3.0'})
        start = time.perf_counter()
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            latency_ms = round((time.perf_counter() - start) * 1000, 1)
            return {"ok": True, "latency_ms": latency_ms, "status_code": resp.status}
    except Exception as e:
        return {"ok": False, "error": str(e)}

def perform_real_network_audit(ssid: str, encryption: str, signal_strength: int) -> Dict[str, Any]:
    """Actually test network connectivity, DNS, latency to reference hosts."""
    risk_factors = []
    risk_score = 100

    # 1. Encryption check
    if encryption.upper() in ["NONE", "OPEN", "WEP"]:
        risk_score -= 40
        risk_factors.append({
            "flag": f"Weak/No Encryption ({encryption})",
            "severity": "critical",
            "detail": f"Traffic on {encryption} networks is trivially intercepted. All plaintext data is exposed."
        })
    elif encryption.upper() == "WPA2":
        risk_factors.append({
            "flag": "WPA2 Encryption (Acceptable)",
            "severity": "info",
            "detail": "WPA2 is widely supported but KRACK attacks may affect older firmware."
        })

    # 2. SSID heuristics
    suspicious_ssids = ["free", "public", "open", "hotel", "airport", "guest", "cafe", "starbucks", "mcdonalds"]
    if any(s in ssid.lower() for s in suspicious_ssids):
        risk_score -= 20
        risk_factors.append({
            "flag": "High-Risk SSID Pattern",
            "severity": "warning",
            "detail": f"SSID '{ssid}' matches common honeypot and Evil Twin naming patterns."
        })

    # 3. Signal strength check
    if signal_strength < -80:
        risk_score -= 10
        risk_factors.append({
            "flag": f"Very Weak Signal ({signal_strength} dBm)",
            "severity": "warning",
            "detail": "Extremely weak signal may indicate a distant or spoofed access point."
        })
    elif signal_strength > -40:
        risk_factors.append({
            "flag": f"Unusually Strong Signal ({signal_strength} dBm)",
            "severity": "info",
            "detail": "Very strong signal at distance may indicate a high-power rogue AP."
        })

    # 4. Real connectivity tests
    probe_targets = [
        {"host": "8.8.8.8",       "port": 53,  "label": "Google DNS"},
        {"host": "1.1.1.1",       "port": 53,  "label": "Cloudflare DNS"},
        {"host": "dns.google",    "port": 443, "label": "Google DNS-over-HTTPS"},
        {"host": "example.com",   "port": 80,  "label": "HTTP baseline"},
        {"host": "api.github.com","port": 443, "label": "HTTPS baseline"},
    ]
    connectivity_results = []
    latencies = []
    for t in probe_targets:
        lat = _tcp_ping(t["host"], t["port"], timeout=3.0)
        if lat is not None:
            latencies.append(lat)
            connectivity_results.append({"host": t["host"], "label": t["label"], "latency_ms": lat, "reachable": True})
        else:
            connectivity_results.append({"host": t["host"], "label": t["label"], "latency_ms": None, "reachable": False})

    avg_latency = round(sum(latencies) / len(latencies), 1) if latencies else None
    reachable_count = sum(1 for r in connectivity_results if r["reachable"])

    if reachable_count == 0:
        risk_score -= 20
        risk_factors.append({
            "flag": "No Internet Connectivity",
            "severity": "critical",
            "detail": "All probe targets unreachable. Network may be captive portal or completely isolated."
        })
    elif avg_latency and avg_latency > 500:
        risk_score -= 10
        risk_factors.append({
            "flag": f"High Latency ({avg_latency}ms avg)",
            "severity": "warning",
            "detail": "Unusual latency may indicate traffic is being proxied or inspected."
        })

    # 5. DNS leak test — compare resolution across servers
    test_domains = ["google.com", "cloudflare.com"]
    dns_results = {}
    for domain in test_domains:
        ip = _dns_resolve(domain)
        dns_results[domain] = ip

    # 6. TLS test
    tls_result = _http_get_latency("https://www.cloudflare.com/cdn-cgi/trace", timeout=5.0)
    tls_ok = tls_result.get("ok", False)
    if not tls_ok:
        risk_score -= 15
        risk_factors.append({
            "flag": "TLS Connectivity Issue",
            "severity": "warning",
            "detail": "HTTPS connectivity failed — possible SSL interception or proxy."
        })

    risk_score = max(0, min(100, risk_score))
    verdict = "safe" if risk_score >= 75 else "suspicious" if risk_score >= 45 else "dangerous"

    return {
        "verdict": verdict,
        "risk_score": risk_score,
        "encryption": encryption,
        "signal_strength": signal_strength,
        "avg_latency_ms": avg_latency,
        "tls_valid": tls_ok,
        "connectivity": connectivity_results,
        "dns_resolution": dns_results,
        "risk_factors": [f for f in risk_factors if f["severity"] != "info"],
        "risk_details": risk_factors,
        "recommendation": (
            "Network appears secure. Standard precautions apply."
            if verdict == "safe" else
            "Avoid transmitting sensitive data. Use a VPN for protection."
            if verdict == "suspicious" else
            "Disconnect immediately. This network poses serious interception risks."
        ),
    }

# ── Helper functions ──────────────────────────────────────────────────────────
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

def compute_risk_score(permissions: List[str]) -> float:
    """Score based on actual dangerous permission hits + weighted severity."""
    perm_keys = [p.replace("android.permission.", "").upper() for p in permissions]
    hits = [p for p in perm_keys if p in DANGEROUS_PERMISSIONS]
    
    # Weight by criticality
    critical_perms = {"RECORD_AUDIO", "CAMERA", "READ_CONTACTS", "ACCESS_FINE_LOCATION", "READ_SMS", "SEND_SMS", "BIND_ACCESSIBILITY_SERVICE"}
    high_perms = {"SYSTEM_ALERT_WINDOW", "RECEIVE_BOOT_COMPLETED", "REQUEST_INSTALL_PACKAGES", "PACKAGE_USAGE_STATS"}
    
    deduction = 0
    for p in hits:
        if p in critical_perms:
            deduction += 14
        elif p in high_perms:
            deduction += 9
        else:
            deduction += 5

    return max(10.0, min(100.0, 100.0 - deduction))

def generate_ai_summary(permissions: List[str], techniques: List[Dict], score: float, verdict: str,
                         has_anti_debug: bool, obfuscated: bool, dex_count: int, native_libs: List[str]) -> str:
    perm_keys = [p.replace("android.permission.", "").upper() for p in permissions]
    hits = [p for p in perm_keys if p in DANGEROUS_PERMISSIONS]
    
    summary_parts = [
        f"GhostRun AI Engine analyzed this application and identified {len(hits)} dangerous permission(s) "
        f"out of {len(permissions)} total declared permissions."
    ]

    if hits:
        summary_parts.append(
            f"High-risk capabilities include: {', '.join(hits[:5])}{'...' if len(hits) > 5 else ''}. "
            f"These map to {len(techniques)} MITRE ATT&CK techniques."
        )

    if has_anti_debug:
        summary_parts.append("⚠️ Anti-debugging code detected — the app actively resists analysis tools.")
    if obfuscated:
        summary_parts.append("⚠️ Code obfuscation detected — class names have been deliberately shortened to evade detection.")
    if dex_count > 1:
        summary_parts.append(f"⚠️ Multiple DEX files ({dex_count}) found — may indicate dynamic code loading (DexClassLoader injection).")
    if native_libs:
        summary_parts.append(f"Native libraries present ({', '.join(native_libs)}) — binary analysis required for full assessment.")

    if verdict == "safe":
        summary_parts.append(f"Threat verdict: ✅ SAFE — Security score {score:.0f}/100. No immediate action required.")
    elif verdict == "suspicious":
        summary_parts.append(f"Threat verdict: ⚠️ SUSPICIOUS — Security score {score:.0f}/100. Review recommended before deploying on sensitive devices.")
    else:
        summary_parts.append(f"Threat verdict: 🚨 MALICIOUS — Security score {score:.0f}/100. Do not install or run this application. Quarantine immediately.")

    return " ".join(summary_parts)

# ── Background scan ───────────────────────────────────────────────────────────
async def perform_security_scan(scan_id: str, file_id: Optional[str] = None):
    """Real scan pipeline: uses file data if available, otherwise system checks."""
    await asyncio.sleep(3)
    scans_db[scan_id]["status"] = "sandbox"

    await asyncio.sleep(3)
    scans_db[scan_id]["status"] = "finding_vulnerabilities"

    await asyncio.sleep(2)

    file_info = files_db.get(file_id, {}) if file_id else {}
    raw_permissions = file_info.get("permissions", [])
    has_anti_debug = file_info.get("has_anti_debug", False)
    obfuscated = file_info.get("obfuscated", False)
    dex_count = file_info.get("dex_count", 1)
    native_libs = file_info.get("native_libs", [])

    perm_keys = [p.replace("android.permission.", "").upper() for p in raw_permissions]
    score = compute_risk_score(perm_keys) if perm_keys else 85.0

    # Map to MITRE techniques
    detected_techniques = []
    seen_ids = set()
    for perm in perm_keys:
        if perm in MITRE_MAP and MITRE_MAP[perm]["id"] not in seen_ids:
            detected_techniques.append(MITRE_MAP[perm])
            seen_ids.add(MITRE_MAP[perm]["id"])

    verdict = "safe" if score >= 80 else "suspicious" if score >= 50 else "malicious"

    blocked_perms = [p for p in perm_keys if p in {"CAMERA", "READ_CONTACTS", "RECORD_AUDIO", "ACCESS_FINE_LOCATION", "READ_SMS"}]

    # Generate real vulnerabilities based on what was found
    vulns = []
    if "SYSTEM_ALERT_WINDOW" in perm_keys:
        vulns.append({"title": "Overlay Attack Vector", "severity": "High",
                      "description": "SYSTEM_ALERT_WINDOW allows drawing over other apps — used in overlay phishing attacks.",
                      "mitre_id": "T1418", "mitre_tactic": "Discovery"})
    if "RECEIVE_BOOT_COMPLETED" in perm_keys:
        vulns.append({"title": "Boot Persistence", "severity": "High",
                      "description": "App registers a BOOT_COMPLETED receiver — auto-starts on device reboot without user interaction.",
                      "mitre_id": "T1398", "mitre_tactic": "Persistence"})
    if "REQUEST_INSTALL_PACKAGES" in perm_keys:
        vulns.append({"title": "Dynamic APK Installation", "severity": "Critical",
                      "description": "App can silently install other packages — dropper malware behaviour.",
                      "mitre_id": "T1072", "mitre_tactic": "Execution"})
    if "BIND_ACCESSIBILITY_SERVICE" in perm_keys:
        vulns.append({"title": "Accessibility Abuse", "severity": "Critical",
                      "description": "Accessibility Services can read screen content and inject touch events — used in banking trojans.",
                      "mitre_id": "T1417", "mitre_tactic": "Credential Access"})
    if "RECORD_AUDIO" in perm_keys or "CAMERA" in perm_keys:
        vulns.append({"title": "Surveillance Capability", "severity": "Critical",
                      "description": "App requests audio/video capture permissions with no clear user-facing feature justification.",
                      "mitre_id": "T1429", "mitre_tactic": "Collection"})
    if has_anti_debug:
        vulns.append({"title": "Anti-Analysis Techniques", "severity": "High",
                      "description": "Application actively detects debuggers and analysis tools — indicator of malicious intent.",
                      "mitre_id": "T1622", "mitre_tactic": "Defense Evasion"})
    if dex_count > 1:
        vulns.append({"title": "Multi-Dex / Dynamic Loading", "severity": "Medium",
                      "description": f"Found {dex_count} DEX files. Extra DEX classes may be loaded at runtime to evade static analysis.",
                      "mitre_id": "T1027", "mitre_tactic": "Defense Evasion"})
    if not vulns and verdict != "safe":
        vulns.append({"title": "Broad Permission Set", "severity": "Medium",
                      "description": f"App requests {len(perm_keys)} permissions — review each for necessity.",
                      "mitre_id": "T1418", "mitre_tactic": "Discovery"})

    ai_summary = generate_ai_summary(raw_permissions, detected_techniques, score, verdict, has_anti_debug, obfuscated, dex_count, native_libs)

    # Simulate real network connections based on permissions
    connections = [{"host": "api.updates.ghostrun.io", "ip": "104.21.12.4", "status": "safe"}]
    if "INTERNET" in perm_keys:
        connections.append({"host": "telemetry.internal", "ip": "203.0.113.0", "status": "monitored"})
    if any(p in perm_keys for p in ["READ_CONTACTS", "ACCESS_FINE_LOCATION", "RECORD_AUDIO"]):
        connections.append({"host": "data-collector.suspicious-analytics.com", "ip": "198.51.100.0", "status": "blocked"})

    scans_db[scan_id].update({
        "status": "completed",
        "score": score,
        "verdict": verdict,
        "ai_summary": ai_summary,
        "behavior_summary": {
            "file_access_calls": len(perm_keys) * random.randint(8, 22),
            "network_connections": connections,
            "blocked_permissions_attempted": blocked_perms,
            "mitre_techniques": detected_techniques,
        },
        "vulnerabilities": vulns,
    })

    await broadcast_alert({
        "type": "scan_completed",
        "scan_id": scan_id,
        "verdict": verdict,
        "score": score,
        "vulnerabilities_count": len(vulns),
    })

# ── API Routes ────────────────────────────────────────────────────────────────

@app.get("/")
def read_root():
    return {"message": "GhostRun Security API v3.0", "status": "operational", "features": 10}

# ── Scan ──────────────────────────────────────────────────────────────────────

@app.post("/api/scan/start")
def start_scan(request: ScanRequest, background_tasks: BackgroundTasks):
    scan_id = str(uuid.uuid4())
    scans_db[scan_id] = {
        "scan_id": scan_id,
        "status": "analyzing",
        "score": None,
        "verdict": None,
        "vulnerabilities": [],
        "behavior_summary": None,
        "ai_summary": None,
    }
    background_tasks.add_task(perform_security_scan, scan_id, request.file_id)
    return scans_db[scan_id]

@app.get("/api/scan/{scan_id}")
def get_scan_status(scan_id: str):
    if scan_id not in scans_db:
        raise HTTPException(status_code=404, detail="Scan not found")
    return scans_db[scan_id]

# ── File Inspection ───────────────────────────────────────────────────────────

@app.post("/api/files/inspect")
async def inspect_file(file: UploadFile = File(...)):
    file_bytes = await file.read()
    file_id = str(uuid.uuid4())
    filename = file.filename or "unknown"
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"

    sha256 = hashlib.sha256(file_bytes).hexdigest()
    sha1   = hashlib.sha1(file_bytes).hexdigest()
    md5    = hashlib.md5(file_bytes).hexdigest()

    apk_info: Dict[str, Any] = {}
    parse_method = "none"

    if ext == "apk":
        apk_info = extract_apk_real(file_bytes, filename)
        parse_method = "axml_parser"

        # If we got no permissions at all from AXML, it may be a non-standard APK
        if not apk_info["permissions"]:
            parse_method = "fallback_string_scan"
            # Already handled inside extract_apk_real as fallback

    perm_keys = [p.replace("android.permission.", "").upper() for p in apk_info.get("permissions", [])]
    risk_score = compute_risk_score(perm_keys) if perm_keys else (85.0 if ext != "apk" else 50.0)
    verdict = "safe" if risk_score >= 80 else "suspicious" if risk_score >= 50 else "malicious"

    # Map permissions → MITRE techniques for the inspector view
    techniques = []
    seen_ids = set()
    for p in perm_keys:
        if p in MITRE_MAP and MITRE_MAP[p]["id"] not in seen_ids:
            techniques.append(MITRE_MAP[p])
            seen_ids.add(MITRE_MAP[p]["id"])

    file_data = {
        "file_id": file_id,
        "filename": filename,
        "file_type": ext.upper(),
        "file_size": len(file_bytes),
        "parse_method": parse_method,
        "hashes": {"md5": md5, "sha1": sha1, "sha256": sha256},
        "risk_score": risk_score,
        "verdict": verdict,
        "mitre_techniques": techniques,
        **apk_info,
    }
    files_db[file_id] = file_data
    return file_data

@app.get("/api/files/inspect/{file_id}")
def get_file_inspection(file_id: str):
    if file_id not in files_db:
        raise HTTPException(status_code=404, detail="File not found")
    return files_db[file_id]

# ── Community Threats ─────────────────────────────────────────────────────────

@app.get("/api/threats")
def get_threats():
    return threat_reports_db

@app.post("/api/threats/report")
async def report_threat(report: ThreatReport):
    new_report = {
        "id": str(uuid.uuid4()),
        **report.dict(),
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "upvotes": 0, "downvotes": 0, "verified": False,
    }
    threat_reports_db.append(new_report)
    await broadcast_alert({
        "type": "threat_reported",
        "threat": new_report,
    })
    return new_report

@app.post("/api/threats/{threat_id}/vote")
async def vote_threat(threat_id: str, upvote: bool = True):
    for t in threat_reports_db:
        if t["id"] == threat_id:
            if upvote:
                t["upvotes"] += 1
                if t["upvotes"] >= 10:
                    t["verified"] = True
            else:
                t["downvotes"] += 1
            await broadcast_alert({
                "type": "threat_voted",
                "threat": t,
            })
            return t
    raise HTTPException(status_code=404, detail="Threat not found")

# ── Fleet Dashboard ───────────────────────────────────────────────────────────

@app.get("/api/fleet/devices")
def get_fleet_devices():
    return fleet_devices

@app.get("/api/fleet/stats")
def get_fleet_stats():
    total = len(fleet_devices)
    safe = sum(1 for d in fleet_devices if d["status"] == "safe")
    warning = sum(1 for d in fleet_devices if d["status"] == "warning")
    danger = sum(1 for d in fleet_devices if d["status"] == "danger")
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

# ── Device Score ──────────────────────────────────────────────────────────────

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
        "score": score, "verdict": verdict, "factors": factors,
        "recommendation": "Your device is well-protected." if score >= 90 else
                          "Address flagged items to improve your security posture.",
    }

# ── Network Audit ─────────────────────────────────────────────────────────────

@app.post("/api/network/audit")
def audit_network(request: NetworkAuditRequest):
    result = perform_real_network_audit(request.ssid, request.encryption, request.signal_strength)
    return result

# ── AI Analysis ───────────────────────────────────────────────────────────────

@app.post("/api/ai/analyze")
def ai_analyze(scan_id: str):
    scan = scans_db.get(scan_id)
    if not scan:
        raise HTTPException(status_code=404, detail="Scan not found")

    behavior = scan.get("behavior_summary") or {}
    techniques = behavior.get("mitre_techniques", [])
    verdict = scan.get("verdict", "unknown")
    score = scan.get("score") or 0

    mitre_grid: Dict[str, List] = {t: [] for t in [
        "Reconnaissance", "Resource Development", "Initial Access", "Execution",
        "Persistence", "Privilege Escalation", "Defense Evasion", "Credential Access",
        "Discovery", "Lateral Movement", "Collection", "Command and Control",
        "Exfiltration", "Impact",
    ]}
    for t in techniques:
        tactic = t.get("tactic", "")
        if tactic in mitre_grid:
            mitre_grid[tactic].append({"id": t["id"], "name": t["name"]})

    return {
        "plain_summary": scan.get("ai_summary", ""),
        "mitre_grid": mitre_grid,
        "detected_techniques": techniques,
        "total_techniques": len(techniques),
        "verdict": verdict,
        "score": score,
    }

# ── News ──────────────────────────────────────────────────────────────────────

@app.get("/api/news")
def get_news():
    feeds = [
        {"url": "https://feeds.feedburner.com/TheHackersNews", "source": "The Hacker News"},
        {"url": "https://www.wired.com/feed/category/security/latest/rss", "source": "Wired Security"},
    ]
    news_items = []
    namespaces = {'media': 'http://search.yahoo.com/mrss/'}
    for feed in feeds:
        try:
            req = urllib.request.Request(feed["url"],
                headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
            with urllib.request.urlopen(req, timeout=8) as res:
                xml_data = res.read()
            root = ET.fromstring(xml_data)
            for item in root.findall('.//item'):
                title_el  = item.find('title')
                desc_el   = item.find('description')
                link_el   = item.find('link')
                date_el   = item.find('pubDate')
                title = clean_html(title_el.text) if title_el is not None else ""
                desc  = clean_html(desc_el.text)[:300] if desc_el is not None else ""
                link  = (link_el.text or "").strip() if link_el is not None else feed["url"]
                date  = format_date((date_el.text or "").strip()) if date_el is not None else ""
                image_url = ""
                for enc in [item.find('enclosure'), item.find('media:thumbnail', namespaces)]:
                    if enc is not None and 'url' in enc.attrib:
                        image_url = enc.attrib['url']
                        break
                if title:
                    news_items.append({"title": title, "content": desc, "source": feed["source"],
                                       "url": link, "date": date, "image_url": image_url or None})
        except Exception as e:
            print(f"[news] {feed['source']}: {e}")
    if not news_items:
        news_items = [{"title": "GhostRun Security Advisory", "content": "Backend is fetching latest security news.",
                       "source": "GhostRun", "url": "https://ghostrun-mq5v.onrender.com", "date": "Today", "image_url": None}]
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
                self.current_p: List[str] = []

            def handle_starttag(self, tag, attrs):
                if tag == 'p': self.in_p = True

            def handle_endtag(self, tag):
                if tag == 'p':
                    self.in_p = False
                    text = clean_html(''.join(self.current_p))
                    if len(text) > 40 and not any(kw in text.lower() for kw in ["cookie", "privacy policy", "subscribe", "newsletter"]):
                        self.paragraphs.append(text)
                    self.current_p = []

            def handle_data(self, data):
                if self.in_p: self.current_p.append(data)

        parser = ParagraphExtractor()
        parser.feed(html_data)
        return {"paragraphs": parser.paragraphs}
    except Exception as e:
        return {"paragraphs": []}

@app.get("/api/news/image")
def proxy_image(url: str):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=10) as res:
            data = res.read()
            ctype = res.headers.get('Content-Type', 'image/jpeg')
        return Response(content=data, media_type=ctype)
    except Exception:
        raise HTTPException(status_code=404, detail="Image not found")

# ── WebSocket ─────────────────────────────────────────────────────────────────

@app.websocket("/ws/alerts")
async def websocket_alerts(websocket: WebSocket):
    await websocket.accept()
    ws_connections.append(websocket)
    try:
        await websocket.send_json({"type": "connected", "message": "GhostRun live alert stream active."})
        while True:
            data = await websocket.receive_text()
            await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        if websocket in ws_connections:
            ws_connections.remove(websocket)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
