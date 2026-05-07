#!/usr/bin/env python3
import os
import sys

PASSWORD_FILE = os.environ.get("RBW_MASTER_PASSWORD_FILE", "/home/node/.openclaw/workspace/skills/rbw_master_password")

def assuan_escape(value: str) -> str:
    # Assuan data line escaping: escape %, CR, LF.
    return (
        value
        .replace("%", "%25")
        .replace("\r", "%0D")
        .replace("\n", "%0A")
    )

try:
    with open(PASSWORD_FILE, "r", encoding="utf-8") as f:
        password = f.read().rstrip("\n")
except Exception as e:
    print(f"ERR 83886179 failed to read password: {e}", flush=True)
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
PY