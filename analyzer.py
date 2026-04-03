"""
analyzer.py
Orchestrates the APK analysis pipeline for Ghostrun.
This module is the single callable unit that main.py and (later) the backend API will use.
"""

import os
import time
import json
from datetime import datetime

import adb_utils


class SandboxAnalyzer:
    def __init__(self, apk_path: str, output_dir: str = "output"):
        self.apk_path = os.path.abspath(os.path.expanduser(apk_path))
        self.output_dir = output_dir
        os.makedirs(self.output_dir, exist_ok=True)

    # ── Public entry point ────────────────────────────────────────────────────

    def run(self) -> dict:
        """
        Full pipeline. Returns a result dict matching the V1 JSON contract:
        {
            "status":      "success" | "error",
            "package":     str,
            "permissions": [str, ...],
            "logs":        str,
            "screenshots": [str, ...],
            "error":       str          # only present on failure
        }
        """
        result = {
            "status": "error",
            "package": None,
            "permissions": [],
            "logs": "",
            "screenshots": [],
        }

        # ── Step 1: Validate APK ──────────────────────────────────────────────
        if not os.path.isfile(self.apk_path):
            return self._fail(result, f"APK file not found: {self.apk_path}")

        # ── Step 2: Check emulator ────────────────────────────────────────────
        print("\n[analyzer] Checking for connected device/emulator ...")
        if not adb_utils.wait_for_device(timeout=60):
            return self._fail(result, "No device/emulator found. Start one first.")

        # ── Step 3: Static extraction (no device needed) ──────────────────────
        print("[analyzer] Extracting package name ...")
        package = adb_utils.extract_package_name(self.apk_path)
        if not package:
            return self._fail(result, "Could not extract package name. Is aapt installed?")
        result["package"] = package
        print(f"[analyzer] Package: {package}")

        print("[analyzer] Extracting permissions ...")
        result["permissions"] = adb_utils.extract_permissions(self.apk_path)
        print(f"[analyzer] Found {len(result['permissions'])} permissions.")

        launcher_activity = adb_utils.get_launcher_activity(self.apk_path)

        # ── Step 4: Install ───────────────────────────────────────────────────
        print("[analyzer] Installing APK ...")
        success, msg = adb_utils.install_apk(self.apk_path)
        if not success:
            return self._fail(result, f"APK install failed: {msg}")
        print("[analyzer] Install successful.")

        # ── Step 5: Prepare logcat ────────────────────────────────────────────
        adb_utils.clear_logcat()

        # ── Step 6: Launch app ────────────────────────────────────────────────
        launched, msg = adb_utils.launch_app(package, launcher_activity)
        if not launched:
            self._cleanup(package)
            return self._fail(result, f"Failed to launch app: {msg}")
        print("[analyzer] App launched. Observing for 10 seconds ...")

        # ── Step 7: Multi-Screenshot & Observation Phase ──────────────────────
        print("[analyzer] Observing app & capturing 4 screenshots ...")
        observation_intervals = [2, 3, 3, 3]  # Intervals in seconds: 2s, 5s, 8s, 11s
        
        for i, interval in enumerate(observation_intervals):
            time.sleep(interval)
            
            shot_name = f"screen_{package}_t{sum(observation_intervals[:i+1])}s_{self._timestamp()}.png"
            screenshot_path = os.path.join(self.output_dir, shot_name)
            
            shot_ok, shot_result = adb_utils.take_screenshot(screenshot_path)
            if shot_ok:
                result["screenshots"].append(shot_result)
                print(f"[analyzer] Screenshot {i+1}/4 saved: {shot_result}")
            else:
                print(f"[analyzer] Screenshot {i+1}/4 warning: {shot_result}")

        # ── Step 8: Capture logcat (dump current buffer) ──────────────────────
        print("[analyzer] Finalizing logcat dump ...")
        result["logs"] = adb_utils.capture_logcat(duration=0, package=package)

        # ── Step 9: Cleanup ───────────────────────────────────────────────────
        self._cleanup(package)

        # ── Step 10: Persist result JSON ──────────────────────────────────────
        result["status"] = "success"
        self._save_result(result, package)

        return result

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _fail(self, result: dict, error_msg: str) -> dict:
        print(f"[analyzer] ERROR: {error_msg}")
        result["status"] = "error"
        result["error"] = error_msg
        return result

    def _cleanup(self, package: str) -> None:
        print(f"[analyzer] Uninstalling {package} ...")
        removed = adb_utils.uninstall_package(package)
        if removed:
            print("[analyzer] Uninstall complete.")
        else:
            print("[analyzer] Uninstall skipped (package may not have been installed).")

    def _timestamp(self) -> str:
        return datetime.now().strftime("%Y%m%d_%H%M%S")

    def _save_result(self, result: dict, package: str) -> None:
        json_path = os.path.join(
            self.output_dir,
            f"result_{package}_{self._timestamp()}.json",
        )
        with open(json_path, "w") as f:
            json.dump(result, f, indent=2)
        print(f"[analyzer] Result saved: {json_path}")
