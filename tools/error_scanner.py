import subprocess
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUTPUT_FILE = ROOT / "errors.json"

# Flutter modern analyze output pattern
ERROR_PATTERN = re.compile(
    r"error\s+•\s+(?P<message>.+?)\s+•\s+(?P<file>.+\.dart):(?P<line>\d+):(?P<col>\d+)\s+•\s+(?P<type>[a-z_]+)"
)

def main():
    print("🔍 Running flutter analyze ...")

    process = subprocess.run(
        [r"C:\flutter\bin\flutter.bat", "analyze"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="ignore"
    )

    output = process.stdout + "\n" + process.stderr
    errors = []

    for line in output.splitlines():
        match = ERROR_PATTERN.search(line)
        if match:
            errors.append({
                "file": match.group("file"),
                "line": int(match.group("line")),
                "column": int(match.group("col")),
                "type": match.group("type"),
                "message": match.group("message"),
            })

    if not errors:
        OUTPUT_FILE.write_text("[]", encoding="utf-8")
    else:
        OUTPUT_FILE.write_text(
            json.dumps(errors, indent=2, ensure_ascii=False),
            encoding="utf-8"
        )

    print(f"✅ Found {len(errors)} errors")
    print(f"📄 Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
