"""
adb_utils.py
Core ADB command wrappers for Ghostrun sandbox.
All functions return (stdout, stderr, returncode) tuples.
"""

import subprocess
import time
import os
from typing import Optional


def run_cmd(args: list[str], timeout: int = 30) -> tuple[str, str, int]:
    """Run a shell command and return (stdout, stderr, returncode)."""
    try:
        result = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
        )
        return result.stdout.strip(), result.stderr.strip(), result.returncode
    except subprocess.TimeoutExpired:
        return "", f"Command timed out after {timeout}s: {' '.join(args)}", 1
    except FileNotFoundError:
        return "", f"Command not found: {args[0]}", 1


# ── Emulator ──────────────────────────────────────────────────────────────────

def get_connected_devices() -> list[str]:
    """Return list of connected ADB device serials."""
    stdout, _, rc = run_cmd(["adb", "devices"])
    if rc != 0:
        return []
    devices = []
    for line in stdout.splitlines()[1:]:  # skip header
        line = line.strip()
        if line and "device" in line and "offline" not in line:
            devices.append(line.split()[0])
    return devices


def wait_for_device(timeout: int = 60) -> bool:
    """Wait until at least one device/emulator is ready. Returns True on success."""
    print(f"[adb] Waiting for device (up to {timeout}s)...")
    deadline = time.time() + timeout
    while time.time() < deadline:
        if get_connected_devices():
            stdout, _, _ = run_cmd(["adb", "shell", "getprop", "sys.boot_completed"])
            if stdout.strip() == "1":
                print("[adb] Device ready.")
                return True
        time.sleep(3)
    return False


# ── APK Install ───────────────────────────────────────────────────────────────

def install_apk(apk_path: str) -> tuple[bool, str]:
    """
    Install APK onto connected device.
    adb install -r <apk>   (-r = replace existing)
    Returns (success, message).
    """
    if not os.path.isfile(apk_path):
        return False, f"APK not found: {apk_path}"

    print(f"[adb] Installing {apk_path} ...")
    stdout, stderr, rc = run_cmd(["adb", "install", "-r", "--bypass-low-target-sdk-block", apk_path], timeout=300)

    combined = (stdout + stderr).lower()
    if rc == 0 and "success" in combined:
        return True, stdout
    return False, stderr or stdout


def uninstall_package(package: str) -> bool:
    """Silently uninstall a package. Returns True if removed."""
    stdout, _, rc = run_cmd(["adb", "uninstall", package], timeout=30)
    return rc == 0 and "success" in stdout.lower()


# ── Package Name ──────────────────────────────────────────────────────────────

def extract_package_name(apk_path: str) -> Optional[str]:
    """
    Use aapt to pull the package name from the APK manifest.
    Command: aapt dump badging <apk>  -- look for 'package: name='
    Falls back to aapt2 if aapt is unavailable.
    """
    for tool in ["aapt", "aapt2"]:
        stdout, _, rc = run_cmd([tool, "dump", "badging", apk_path], timeout=30)
        if rc == 0:
            for line in stdout.splitlines():
                if line.startswith("package: name="):
                    # e.g.  package: name='com.example.app' versionCode=...
                    part = line.split("name=")[1]
                    return part.strip("'\"").split("'")[0].split('"')[0]
    return None


# ── Permissions ───────────────────────────────────────────────────────────────

def extract_permissions(apk_path: str) -> list[str]:
    """
    Use aapt to list declared permissions.
    Command: aapt dump permissions <apk>
    Returns list like ['android.permission.INTERNET', ...]
    """
    permissions = []
    for tool in ["aapt", "aapt2"]:
        stdout, _, rc = run_cmd([tool, "dump", "permissions", apk_path], timeout=30)
        if rc == 0:
            for line in stdout.splitlines():
                line = line.strip()
                if line.startswith("uses-permission:"):
                    # uses-permission: name='android.permission.INTERNET'
                    perm = line.split("name=")[1].strip("'\" ") if "name=" in line else ""
                    if perm:
                        permissions.append(perm)
            return permissions
    return permissions


# ── App Launch ────────────────────────────────────────────────────────────────

def get_launcher_activity(apk_path: str) -> Optional[str]:
    """
    Extract the main launcher activity via aapt.
    Command: aapt dump badging <apk>  → look for launchable-activity
    """
    for tool in ["aapt", "aapt2"]:
        stdout, _, rc = run_cmd([tool, "dump", "badging", apk_path], timeout=30)
        if rc == 0:
            for line in stdout.splitlines():
                if "launchable-activity" in line and "name=" in line:
                    activity = line.split("name=")[1].split("'")[1] if "'" in line else ""
                    return activity or None
    return None


def launch_app(package: str, activity: Optional[str] = None) -> tuple[bool, str]:
    """
    Launch app on device.
    With activity: adb shell am start -n <package>/<activity>
    Without      : adb shell monkey -p <package> -c android.intent.category.LAUNCHER 1
    """
    if activity:
        cmd = ["adb", "shell", "am", "start", "-n", f"{package}/{activity}"]
    else:
        cmd = [
            "adb", "shell", "monkey",
            "-p", package,
            "-c", "android.intent.category.LAUNCHER", "1",
        ]

    print(f"[adb] Launching {package} ...")
    stdout, stderr, rc = run_cmd(cmd, timeout=20)
    if rc == 0:
        return True, stdout
    return False, stderr or stdout


# ── Logcat ────────────────────────────────────────────────────────────────────

def clear_logcat() -> None:
    """Flush logcat buffer before the test run. adb logcat -c"""
    run_cmd(["adb", "logcat", "-c"])
    print("[adb] Logcat cleared.")


def capture_logcat(duration: int = 10, package: str = "") -> str:
    """
    Capture logcat for `duration` seconds.
    adb logcat -d  (dump current buffer after sleep)
    Optionally filter by package tag if provided.
    """
    time.sleep(duration)
    stdout, _, _ = run_cmd(["adb", "logcat", "-d"], timeout=duration + 15)
    if package and stdout:
        # Soft filter: keep lines containing the package name
        filtered = [l for l in stdout.splitlines() if package in l or "AndroidRuntime" in l]
        return "\n".join(filtered) if filtered else stdout
    return stdout


# ── Screenshot ────────────────────────────────────────────────────────────────

def take_screenshot(output_path: str = "screenshot.png") -> tuple[bool, str]:
    """
    Capture screen via:
      adb shell screencap -p /sdcard/screen.png
      adb pull /sdcard/screen.png <output_path>
    Returns (success, local_path_or_error).
    """
    remote = "/sdcard/screen.png"
    _, err, rc = run_cmd(["adb", "shell", "screencap", "-p", remote], timeout=15)
    if rc != 0:
        return False, f"screencap failed: {err}"

    stdout, err, rc = run_cmd(["adb", "pull", remote, output_path], timeout=15)
    if rc == 0 and os.path.isfile(output_path):
        # Cleanup remote file
        run_cmd(["adb", "shell", "rm", remote])
        return True, output_path
    return False, f"adb pull failed: {err}"
