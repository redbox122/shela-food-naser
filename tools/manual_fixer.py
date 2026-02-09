import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS_FILE = ROOT / "errors.json"

def main():
    errors = json.loads(ERRORS_FILE.read_text(encoding="utf-8"))

    if not errors:
        print("🎉 No errors found. Project is clean!")
        return

    for i, err in enumerate(errors, start=1):
        file_path = ROOT / err["file"]

        print("\n" + "=" * 60)
        print(f"[{i}/{len(errors)}]")
        print(f"FILE  : {err['file']}")
        print(f"LINE  : {err['line']}")
        print(f"ERROR : {err['type']}")
        print("=" * 60)

        if not file_path.exists():
            print("❌ File not found, skipping...")
            continue

        lines = file_path.read_text(encoding="utf-8").splitlines()

        start = max(err["line"] - 3, 0)
        end = min(err["line"] + 2, len(lines))

        print("\n--- OLD CODE ---")
        for idx in range(start, end):
            prefix = "👉" if idx == err["line"] - 1 else "  "
            print(f"{prefix} {idx+1}: {lines[idx]}")

        print("\n🛑 Fix manually:")
        print("1️⃣ خذ هذا الكود")
        print("2️⃣ ابعته لشات GPT")
        print("3️⃣ رجّع السطر المصحّح")
        input("⏸️ اضغط Enter بعد ما تجهز الحل...")

        print("\n✏️ الصق السطر الجديد (سطر واحد فقط):")
        new_line = input("> ")

        confirm = input("❓ تأكيد الاستبدال؟ (y/n): ").lower()
        if confirm != "y":
            print("⏭️ تم التخطي")
            continue

        lines[err["line"] - 1] = new_line
        file_path.write_text("\n".join(lines), encoding="utf-8")

        print("✅ تم التعديل")

    print("\n🎯 انتهى السكريبت")

if __name__ == "__main__":
    main()
