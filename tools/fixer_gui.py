import json
from pathlib import Path
import tkinter as tk
from tkinter import messagebox

ROOT = Path(__file__).resolve().parents[1]
ERRORS_FILE = ROOT / "errors.json"


class FixerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Flutter Error Fixer")
        self.root.geometry("800x500")

        if not ERRORS_FILE.exists():
            messagebox.showerror("Error", "errors.json غير موجود")
            root.destroy()
            return

        self.errors = json.loads(ERRORS_FILE.read_text(encoding="utf-8"))
        self.index = 0

        self.build_ui()
        self.load_error()

    def build_ui(self):
        self.info = tk.Label(self.root, font=("Segoe UI", 10), justify="left")
        self.info.pack(pady=10, anchor="w", padx=10)

        tk.Label(self.root, text="❌ Old Code").pack(anchor="w", padx=10)
        self.old_code = tk.Text(self.root, height=3, bg="#ffecec")
        self.old_code.pack(fill="x", padx=10)

        tk.Label(self.root, text="✅ New Code").pack(anchor="w", padx=10)
        self.new_code = tk.Text(self.root, height=3)
        self.new_code.pack(fill="x", padx=10)

        btn_frame = tk.Frame(self.root)
        btn_frame.pack(pady=20)

        tk.Button(btn_frame, text="Apply ✔", width=15, command=self.apply_fix).pack(
            side="left", padx=10
        )
        tk.Button(btn_frame, text="Skip ➡", width=15, command=self.next_error).pack(
            side="left", padx=10
        )

    def load_error(self):
        if self.index >= len(self.errors):
            messagebox.showinfo("Done", "🎉 انتهت جميع الأخطاء")
            self.root.destroy()
            return

        err = self.errors[self.index]
        file_path = ROOT / err["file"]

        if not file_path.exists():
            self.index += 1
            self.load_error()
            return

        lines = file_path.read_text(encoding="utf-8").splitlines()
        line_no = err["line"] - 1

        if line_no >= len(lines):
            self.index += 1
            self.load_error()
            return

        self.current_file = file_path
        self.current_line = line_no
        self.current_lines = lines

        self.info.config(
            text=(
                f"🧨 Error {self.index + 1} / {len(self.errors)}\n"
                f"📄 File: {err['file']}\n"
                f"📍 Line: {err['line']}\n"
                f"🚫 Type: {err['type']}\n"
                f"💬 {err['message']}"
            )
        )

        self.old_code.delete("1.0", tk.END)
        self.old_code.insert(tk.END, lines[line_no])

        self.new_code.delete("1.0", tk.END)

    def apply_fix(self):
        new = self.new_code.get("1.0", tk.END).strip()
        if not new:
            messagebox.showwarning("Warning", "الكود الجديد فارغ")
            return

        self.current_lines[self.current_line] = new
        self.current_file.write_text(
            "\n".join(self.current_lines), encoding="utf-8"
        )

        self.next_error()

    def next_error(self):
        self.index += 1
        self.load_error()


if __name__ == "__main__":
    root = tk.Tk()
    app = FixerApp(root)
    root.mainloop()
