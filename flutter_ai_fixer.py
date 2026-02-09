import os
import re

ROOT = "lib"

PATTERN = re.compile(
    r"=\s*json\[['\"]([^'\"]+)['\"]\]\s*;"
)

def process_file(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    original = content

    def replacer(match):
        key = match.group(1)
        return f"= json['{key}']?.toString();"

    content = PATTERN.sub(replacer, content)

    if content != original:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✔ fixed:", path)

for root, _, files in os.walk(ROOT):
    for file in files:
        if file.endswith(".dart") and "model" in file.lower():
            process_file(os.path.join(root, file))
