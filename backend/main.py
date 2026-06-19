from fastapi import FastAPI, BackgroundTasks, HTTPException, Response
from pydantic import BaseModel
from typing import List, Optional
import time
import uuid
import html
import re
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser


from fastapi.middleware.cors import CORSMiddleware

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
    # Changed default port to 8001 since Jenkins is on 8080
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
