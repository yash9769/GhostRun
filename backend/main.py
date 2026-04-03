from fastapi import FastAPI, BackgroundTasks, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import time
import uuid

app = FastAPI(title="GhostRun Security API")

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

@app.get("/api/news", response_model=List[NewsItem])
def get_news():
    return [
        NewsItem(title="Critical Zero-Day exploit found in iOS", content="A new critical vulnerability...", source="SecurityTracker"),
        NewsItem(title="New Malware Campaign Targets Mobile Banking", content="Security researchers have identified...", source="CyberNews"),
    ]

if __name__ == "__main__":
    import uvicorn
    # Changed default port to 8001 since Jenkins is on 8080
    uvicorn.run("main:app", host="0.0.0.0", port=8001, reload=True)
