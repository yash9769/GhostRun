"""
main.py
CLI entry point for Ghostrun sandbox (V1).

Usage:
    python main.py path/to/app.apk
    python main.py path/to/app.apk --output ./results
    python main.py path/to/app.apk --json-only
"""

import argparse
import json
import sys

from analyzer import SandboxAnalyzer


def parse_args():
    parser = argparse.ArgumentParser(
        prog="sandbox",
        description="Ghostrun — Local APK Sandbox (V1)",
    )
    parser.add_argument(
        "apk",
        help="Path to the APK file to analyse",
    )
    parser.add_argument(
        "--output", "-o",
        default="output",
        help="Directory to store screenshots and result JSON (default: ./output)",
    )
    parser.add_argument(
        "--json-only",
        action="store_true",
        help="Suppress progress output; print only the final JSON result",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    # Suppress verbose output when --json-only is set
    if args.json_only:
        import io, contextlib
        f = io.StringIO()
        with contextlib.redirect_stdout(f):
            result = SandboxAnalyzer(args.apk, output_dir=args.output).run()
    else:
        print("=" * 60)
        print("  Ghostrun — APK Sandbox")
        print("=" * 60)
        result = SandboxAnalyzer(args.apk, output_dir=args.output).run()
        print("=" * 60)

    # Always print final JSON to stdout (parseable by backend later)
    print(json.dumps(result, indent=2))

    sys.exit(0 if result["status"] == "success" else 1)


if __name__ == "__main__":
    main()
