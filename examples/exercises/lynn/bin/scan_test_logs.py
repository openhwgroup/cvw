#!/usr/bin/env -S uv run --script
# James Kaden Cassidy
# kacassidy@hmc.edu
# Dec 25 2025

import sys
from pathlib import Path

PASS_STR = "INFO: Test Passed!"
FAIL_STR = "ERROR: Test Failed"

def main():
    # Default path: work (relative to repo root)
    runs_dir = Path("work")

    if not runs_dir.exists():
        print(f"ERROR: directory not found: {runs_dir}")
        return 2

    log_files = sorted(runs_dir.rglob("*.log"))

    if not log_files:
        print("No .log files found.")
        return 0

    passed = []
    failed = []
    unknown = []

    for log in log_files:
        try:
            text = log.read_text(errors="ignore")
        except Exception as e:
            print(f"ERROR: could not read {log}: {e}")
            unknown.append(log)
            continue

        has_pass = PASS_STR in text
        has_fail = FAIL_STR in text

        if has_fail:
            failed.append(log)
        elif has_pass:
            passed.append(log)
        else:
            unknown.append(log)

    # ---- Report ----
    print("=== Test Log Summary ===")
    print(f"Total logs:      {len(log_files)}")
    print(f"Passed:          {len(passed)}")
    print(f"Failed:          {len(failed)}")
    print(f"Unclassified:    {len(unknown)}")
    print()

    if failed:
        print("❌ Failed tests:")
        for f in failed:
            print(f"  {f}")
        print()

    if unknown:
        print("⚠️  Logs with no pass/fail marker:")
        for u in unknown:
            print(f"  {u}")
        print()

    # Exit status: fail build if any test failed
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
