# CheckBeforeInstall — Local APK Sandbox (V1)

A minimal, standalone Python sandbox that installs an APK on an Android emulator,
observes it for 10 seconds, and returns a structured JSON report.

---

## Folder Structure

```
sandbox/
├── adb_utils.py      # All ADB / aapt command wrappers
├── analyzer.py       # Pipeline orchestrator
├── main.py           # CLI entry point
├── output/           # Auto-created — screenshots + result JSONs land here
└── README.md
```

---

## Prerequisites

| Tool | Why | How to verify |
|------|-----|---------------|
| Python 3.10+ | Runtime | `python --version` |
| Android SDK (platform-tools) | `adb` | `adb version` |
| Android SDK (build-tools) | `aapt` | `aapt version` |
| Android Emulator | Running device | `emulator -list-avds` |

### Add SDK tools to PATH (if not already)
```bash
# macOS / Linux — add to ~/.zshrc or ~/.bashrc
export ANDROID_HOME=$HOME/Library/Android/sdk           # macOS default
export PATH=$PATH:$ANDROID_HOME/platform-tools           # adb
export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0      # aapt (adjust version)
```

---

## How to Run

### 1. Start your emulator
```bash
# List available AVDs
emulator -list-avds

# Start one (replace Pixel_6_API_33 with your AVD name)
emulator -avd Pixel_6_API_33 &

# Verify ADB sees it (wait ~30s for boot)
adb devices
```

Expected output:
```
List of devices attached
emulator-5554   device
```

### 2. Run the sandbox
```bash
# Basic usage
python main.py /path/to/your/app.apk

# Custom output directory
python main.py /path/to/your/app.apk --output ./results

# Silent mode — only print final JSON (useful for piping)
python main.py /path/to/your/app.apk --json-only
```

### 3. Example output
```json
{
  "status": "success",
  "package": "com.example.app",
  "permissions": [
    "android.permission.INTERNET",
    "android.permission.READ_SMS",
    "android.permission.ACCESS_FINE_LOCATION"
  ],
  "logs": "04-01 10:22:01.123  1234  1234 I ActivityManager: START ...\n...",
  "screenshots": [
    "output/screen_com.example.app_20240401_102204.png"
  ]
}
```

Error case:
```json
{
  "status": "error",
  "package": null,
  "permissions": [],
  "logs": "",
  "screenshots": [],
  "error": "APK install failed: INSTALL_FAILED_NO_MATCHING_ABIS"
}
```

---

## Exact ADB / aapt Commands Used

| Step | Command |
|------|---------|
| Check connected devices | `adb devices` |
| Wait for boot | `adb shell getprop sys.boot_completed` |
| Install APK | `adb install -r <apk_path>` |
| Uninstall package | `adb uninstall <package>` |
| Extract package name | `aapt dump badging <apk>` → parse `package: name=` |
| Extract permissions | `aapt dump permissions <apk>` → parse `uses-permission:` |
| Get launcher activity | `aapt dump badging <apk>` → parse `launchable-activity` |
| Launch app (with activity) | `adb shell am start -n <package>/<activity>` |
| Launch app (fallback) | `adb shell monkey -p <package> -c android.intent.category.LAUNCHER 1` |
| Clear logcat buffer | `adb logcat -c` |
| Capture logcat dump | `adb logcat -d` |
| Take screenshot | `adb shell screencap -p /sdcard/screen.png` |
| Pull screenshot | `adb pull /sdcard/screen.png <local_path>` |
| Remove remote screenshot | `adb shell rm /sdcard/screen.png` |

---

## Architecture

```
main.py  ──calls──▶  SandboxAnalyzer.run()  ──uses──▶  adb_utils.*
   │                        │
   │              ┌─────────▼────────────────────────┐
   │              │  1. validate APK exists            │
   │              │  2. wait_for_device()              │
   │              │  3. extract_package_name()  aapt   │
   │              │  4. extract_permissions()   aapt   │
   │              │  5. install_apk()           adb    │
   │              │  6. clear_logcat()          adb    │
   │              │  7. launch_app()            adb    │
   │              │  8. take_screenshot()       adb    │
   │              │  9. capture_logcat()        adb    │
   │              │ 10. uninstall_package()     adb    │
   │              └──────────────────────────────────┘
   │
   └──prints──▶  JSON result (stdout)
                 PNG + JSON saved to ./output/
```

---

## Backend Integration (V2 Notes)

When the backend is ready, it can call the sandbox in two ways:

**Option A — subprocess (simplest)**
```python
import subprocess, json

result = subprocess.run(
    ["python", "main.py", apk_path, "--json-only"],
    capture_output=True, text=True
)
data = json.loads(result.stdout)
```

**Option B — import as module**
```python
from analyzer import SandboxAnalyzer

result = SandboxAnalyzer(apk_path, output_dir="/tmp/sandbox_out").run()
```

---

## Common Errors

| Error message | Cause | Fix |
|---------------|-------|-----|
| `No device/emulator found` | Emulator not running | Start AVD first |
| `APK not found` | Wrong path | Check path, use absolute path |
| `Could not extract package name` | `aapt` missing | Add build-tools to PATH |
| `INSTALL_FAILED_NO_MATCHING_ABIS` | x86 APK on ARM emulator (or vice versa) | Use matching emulator image |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Old version with different signature installed | `adb uninstall <package>` manually |
| `screencap failed` | Emulator locked / no display | Unlock device, ensure it's fully booted |
