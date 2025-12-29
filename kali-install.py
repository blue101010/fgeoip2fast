#!/usr/bin/env python3
import subprocess
import sys
import os
import shutil

def install():
    """
    Helper script to install geoip2fast on Kali Linux / Debian systems
    handling PEP 668 (Externally Managed Environments) and permissions.
    """
    print("[*] Starting installation for Kali Linux...")

    # Check if pip is available
    if shutil.which("pip") is None and shutil.which("pip3") is None:
        print("[!] pip is not found. Please install it using: sudo apt install python3-pip")
        sys.exit(1)

    # Check if running as root
    is_root = False
    if hasattr(os, "geteuid"):
        is_root = os.geteuid() == 0
    
    # Construct the pip command
    # We use sys.executable to ensure we use the same python interpreter invoking this script
    cmd = [sys.executable, "-m", "pip", "install", "."]

    if is_root:
        print("[*] Running as root. Installing system-wide.")
        # Modern Kali (Debian 12+) requires --break-system-packages for global pip installs
        # to acknowledge the risk of conflicting with apt packages.
        cmd.append("--break-system-packages")
    else:
        print("[*] Not running as root. Installing to user directory (~/.local).")
        cmd.append("--user")
        # Even for user installs, PEP 668 might trigger.
        cmd.append("--break-system-packages")

    print(f"[*] Executing: {' '.join(cmd)}")
    
    try:
        subprocess.check_call(cmd)
        print("\n[+] Installation successful!")
        
        if not is_root:
            print("\n[i] Note: If the 'geoip2fast' command is not found, ensure your local bin is in PATH:")
            print("    export PATH=$PATH:~/.local/bin")
            
    except subprocess.CalledProcessError as e:
        print(f"\n[!] Installation failed with error code {e.returncode}.")
        print("[!] Try running: sudo python3 kali-install.py")
        sys.exit(1)

if __name__ == "__main__":
    install()
