#!/usr/bin/env python3
"""Minimal pinentry emulator for rbw.

rbw-agent speaks the Assuan pinentry protocol to request the master password.
This script answers the small command subset rbw needs and returns the value
from VAULT_MASTER_PASSWORD instead of prompting interactively.

Usage: 
    rbw config set pinentry /path/to/rbw_master_password_from_env.py
"""

import os
import sys

VAULT_MASTER_PASSWORD_ENV = "VAULT_MASTER_PASSWORD"

def assuan_escape(value: str) -> str:
    # Assuan data line escaping: escape %, CR, LF.
    return (
        value
        .replace("%", "%25")
        .replace("\r", "%0D")
        .replace("\n", "%0A")
    )

password = os.environ.get(VAULT_MASTER_PASSWORD_ENV)
if password is None:
    print(f"ERR 83886179 {VAULT_MASTER_PASSWORD_ENV} is not set", flush=True)
    sys.exit(1)

print("OK Pleased to meet you", flush=True)

for line in sys.stdin:
    cmd = line.strip().split(" ", 1)[0].upper()

    if cmd == "GETPIN":
        print(f"D {assuan_escape(password)}", flush=True)
        print("OK", flush=True)
    elif cmd == "BYE":
        print("OK closing connection", flush=True)
        break
    elif cmd in {
        "SETDESC",
        "SETPROMPT",
        "SETTITLE",
        "SETOK",
        "SETCANCEL",
        "SETERROR",
        "SETQUALITYBAR",
        "OPTION",
        "CONFIRM",
        "MESSAGE",
    }:
        print("OK", flush=True)
    else:
        print("OK", flush=True)
