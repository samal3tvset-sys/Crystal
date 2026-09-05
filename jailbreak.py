#!/usr/bin/env python3
import os
import sys
import time
import json
import shutil
import subprocess
import threading
import platform
import zipfile
import urllib.request
from pathlib import Path

try:
    import tkinter as tk
    from tkinter import ttk, scrolledtext, messagebox
    GUI_AVAILABLE = True
except ImportError:
    GUI_AVAILABLE = False

VERSION = "4.0"
DEVICE = platform.system()
IS_IOS = "iOS" in DEVICE or "iPhone" in DEVICE
IS_ANDROID = "Android" in DEVICE

EXPLOITS = [
    {"id": 1, "name": "Credential Dump", "file": "1exploit.c"},
    {"id": 2, "name": "ASLR Leak", "file": "2exploit.c"},
    {"id": 3, "name": "KASLR Bypass", "file": "3exploit.py"},
    {"id": 4, "name": "Buffer Overflow", "file": "4exploit.c"},
    {"id": 5, "name": "Signature Forge", "file": "5exploit.c"},
    {"id": 6, "name": "Audit Bypass", "file": "6exploit.c"},
    {"id": 7, "name": "Audit-ID Replace", "file": "7exploit.c"},
    {"id": 8, "name": "Kdebug Leak", "file": "8exploit.c"},
    {"id": 9, "name": "Kernel Exec", "file": "9exploit.c"},
    {"id": 10, "name": "Tag Overflow", "file": "10exploit.c"},
    {"id": 11, "name": "Panic DoS", "file": "11exploit.c"},
    {"id": 12, "name": "Flipc UAF", "file": "12exploit.c"},
    {"id": 13, "name": "Ipc_hash UAF", "file": "13exploit.c"},
    {"id": 14, "name": "Task UAF", "file": "14exploit.c"},
    {"id": 15, "name": "AMFI Access", "file": "15exploit.c"},
    {"id": 16, "name": "Boot Inject", "file": "16exploit.c"},
    {"id": 17, "name": "Counter Overflow", "file": "17exploit.c"},
]

class ApexJailbreak:
    def __init__(self):
        self.root = None
        self.status_label = None
        self.log_text = None
        self.progress_bar = None
        self.current_exploit = 0
        self.exploit_status = {}
        self.device_info = {}
        self.sileo_installed = False
        self.app_dir = Path(__file__).parent
        self.exploits_dir = self.app_dir / "exploits"
        self.downloads_dir = self.app_dir / "downloads"
        self.logs_dir = self.app_dir / "logs"
        self.exploits_dir.mkdir(exist_ok=True)
        self.downloads_dir.mkdir(exist_ok=True)
        self.logs_dir.mkdir(exist_ok=True)

    def download_exploits(self):
        self.log("[+] Loading exploits...")
        for exp in EXPLOITS:
            src = self.app_dir / exp["file"]
            dst = self.exploits_dir / exp["file"]
            if src.exists():
                shutil.copy(src, dst)
                self.log(f"  OK {exp['name']}")
                self.exploit_status[exp["id"]] = "ready"
            else:
                self.log(f"  MISS {exp['name']}")
                self.exploit_status[exp["id"]] = "missing"
        self.log("[+] Done")

    def get_device_info(self):
        self.log("[+] Getting device info...")
        try:
            if IS_IOS:
                import objc_util
                device = objc_util.ObjCClass('UIDevice').currentDevice()
                self.device_info = {
                    "name": device.name().utf8,
                    "model": device.model().utf8,
                    "system": device.systemName().utf8,
                    "version": device.systemVersion().utf8,
                }
            else:
                self.device_info = {
                    "name": platform.node(),
                    "model": platform.machine(),
                    "system": platform.system(),
                    "version": platform.release(),
                }
        except:
            self.device_info = {
                "name": "Unknown",
                "model": "Unknown",
                "system": platform.system(),
                "version": platform.version(),
            }
        self.log(f"  Device: {self.device_info['name']}")
        self.log(f"  Model: {self.device_info['model']}")
        self.log(f"  System: {self.device_info['system']} {self.device_info['version']}")
        return self.device_info

    def run_exploit(self, exp_id):
        exp = EXPLOITS[exp_id - 1]
        self.log(f"\n[>] Running {exp_id}/17: {exp['name']}...")
        try:
            file_path = self.exploits_dir / exp["file"]
            if not file_path.exists():
                self.log(f"  FAIL: File not found")
                return False
            if exp["file"].endswith(".py"):
                result = subprocess.run(
                    [sys.executable, str(file_path)],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
            else:
                c_file = file_path
                out_file = self.exploits_dir / f"exp_{exp_id}.out"
                subprocess.run(f"gcc -o {out_file} {c_file}", shell=True, capture_output=True, timeout=10)
                if out_file.exists():
                    result = subprocess.run(
                        [str(out_file)],
                        capture_output=True,
                        text=True,
                        timeout=30
                    )
                    out_file.unlink(missing_ok=True)
                else:
                    raise Exception("Compilation failed")
            if result.returncode == 0:
                self.log(f"  OK {exp['name']}")
                self.exploit_status[exp_id] = "success"
                return True
            else:
                self.log(f"  FAIL: {result.stderr[:100]}")
                self.exploit_status[exp_id] = "failed"
                return False
        except Exception as e:
            self.log(f"  ERROR: {str(e)[:100]}")
            self.exploit_status[exp_id] = "error"
            return False

    def run_all_exploits(self):
        self.log("\n" + "="*60)
        self.log("RUNNING ALL EXPLOITS")
        self.log("="*60)
        success_count = 0
        for i in range(1, 18):
            self.current_exploit = i
            self.update_progress(i, 17)
            if self.run_exploit(i):
                success_count += 1
            time.sleep(0.5)
        self.log("\n" + "="*60)
        self.log(f"SUCCESS: {success_count}/17")
        self.log("="*60)
        return success_count == 17

    def install_sileo(self):
        self.log("\n[+] Installing Sileo...")
        try:
            sileo_url = "https://repo.getsileo.app/deb/com.sileo.sileo.deb"
            sileo_path = self.downloads_dir / "sileo.deb"
            self.log(f"  Downloading...")
            urllib.request.urlretrieve(sileo_url, sileo_path)
            self.log(f"  Downloaded: {sileo_path}")
            if shutil.which("dpkg"):
                self.log(f"  Installing via dpkg...")
                result = subprocess.run(
                    ["dpkg", "-i", str(sileo_path)],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    self.log(f"  Sileo installed!")
                    self.sileo_installed = True
                else:
                    self.log(f"  dpkg error: {result.stderr[:100]}")
            else:
                self.log(f"  dpkg not found. Manual install: {sileo_path}")
        except Exception as e:
            self.log(f"  Error: {str(e)[:100]}")

    def create_gui(self):
        if not GUI_AVAILABLE:
            self.console_mode()
            return
        self.root = tk.Tk()
        self.root.title(f"APEX Jailbreak v{VERSION}")
        self.root.geometry("700x650")
        self.root.configure(bg="#1a1a2e")
        title = tk.Label(
            self.root,
            text="APEX JAILBREAK",
            font=("Arial", 24, "bold"),
            fg="#ff6b6b",
            bg="#1a1a2e"
        )
        title.pack(pady=10)
        subtitle = tk.Label(
            self.root,
            text=f"v{VERSION} - 17 exploits",
            font=("Arial", 12),
            fg="#ffd93d",
            bg="#1a1a2e"
        )
        subtitle.pack()
        info_frame = tk.Frame(self.root, bg="#16213e", relief=tk.RIDGE, bd=2)
        info_frame.pack(pady=10, padx=20, fill=tk.X)
        device_text = f"Device: {self.device_info.get('name', 'Unknown')}  |  {self.device_info.get('system', 'Unknown')} {self.device_info.get('version', '')}"
        device_label = tk.Label(
            info_frame,
            text=device_text,
            font=("Arial", 11),
            fg="#ffffff",
            bg="#16213e"
        )
        device_label.pack(pady=5)
        btn_frame = tk.Frame(self.root, bg="#1a1a2e")
        btn_frame.pack(pady=10)
        btn_style = {
            "font": ("Arial", 12, "bold"),
            "width": 18,
            "height": 1,
            "relief": tk.RAISED,
            "bd": 3,
        }
        btn_load = tk.Button(
            btn_frame,
            text="Load Exploits",
            command=self.download_exploits,
            bg="#4ecdc4",
            fg="#1a1a2e",
            **btn_style
        )
        btn_load.grid(row=0, column=0, padx=5, pady=5)
        btn_run = tk.Button(
            btn_frame,
            text="Run Jailbreak",
            command=self.start_jailbreak_thread,
            bg="#ff6b6b",
            fg="#ffffff",
            **btn_style
        )
        btn_run.grid(row=0, column=1, padx=5, pady=5)
        btn_sileo = tk.Button(
            btn_frame,
            text="Install Sileo",
            command=self.install_sileo,
            bg="#ffd93d",
            fg="#1a1a2e",
            **btn_style
        )
        btn_sileo.grid(row=0, column=2, padx=5, pady=5)
        progress_frame = tk.Frame(self.root, bg="#1a1a2e")
        progress_frame.pack(pady=5, padx=20, fill=tk.X)
        self.progress_bar = ttk.Progressbar(
            progress_frame,
            length=650,
            mode="determinate"
        )
        self.progress_bar.pack()
        self.status_label = tk.Label(
            self.root,
            text="Ready",
            font=("Arial", 11),
            fg="#00ff88",
            bg="#1a1a2e"
        )
        self.status_label.pack(pady=5)
        log_frame = tk.Frame(self.root, bg="#0f0f1a")
        log_frame.pack(pady=10, padx=20, fill=tk.BOTH, expand=True)
        self.log_text = scrolledtext.ScrolledText(
            log_frame,
            font=("Courier", 10),
            bg="#0f0f1a",
            fg="#00ff88",
            insertbackground="#00ff88",
            height=15,
            wrap=tk.WORD
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)
        self.log("APEX JAILBREAK v" + VERSION)
        self.log("=" * 50)
        self.get_device_info()
        self.log("=" * 50)
        self.log("Ready")
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
        self.root.mainloop()

    def update_progress(self, current, total):
        if self.progress_bar:
            self.progress_bar["value"] = (current / total) * 100
            self.root.update_idletasks()

    def set_status(self, text):
        if self.status_label:
            self.status_label.config(text=text)
            self.root.update_idletasks()

    def log(self, text):
        if self.log_text:
            self.log_text.insert(tk.END, text + "\n")
            self.log_text.see(tk.END)
            self.root.update_idletasks()
        else:
            print(text)

    def start_jailbreak_thread(self):
        self.set_status("Running jailbreak...")
        self.log("\n" + "=" * 60)
        self.log("RUNNING JAILBREAK")
        self.log("=" * 60)
        thread = threading.Thread(target=self.run_all_exploits)
        thread.daemon = True
        thread.start()

    def on_close(self):
        if messagebox.askokcancel("Exit", "Are you sure?"):
            self.root.destroy()
            sys.exit(0)

    def console_mode(self):
        print("\nAPEX JAILBREAK v" + VERSION)
        print("=" * 50)
        self.get_device_info()
        print("=" * 50)
        while True:
            print("\n[1] Load Exploits")
            print("[2] Run Jailbreak")
            print("[3] Install Sileo")
            print("[4] Exit")
            choice = input("\nChoose: ").strip()
            if choice == "1":
                self.download_exploits()
            elif choice == "2":
                self.run_all_exploits()
            elif choice == "3":
                self.install_sileo()
            elif choice == "4":
                print("Exiting...")
                sys.exit(0)
            else:
                print("Invalid choice")

    def run(self):
        if GUI_AVAILABLE:
            self.create_gui()
        else:
            self.console_mode()

if __name__ == "__main__":
    app = ApexJailbreak()
    if os.geteuid() != 0:
        print("[!] Root recommended")
        print("[!] Use: sudo python3 jailbreak.py")
        if not GUI_AVAILABLE:
            response = input("Continue without root? (y/n): ")
            if response.lower() != "y":
                sys.exit(0)
    app.run()