#!/usr/bin/env python3
import json, time, datetime, subprocess

def text(s, width):
    return {"full_text": f" {s.rjust(width)} "}

def run(command):
    return subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True).stdout

def get_body():
    body = []

    # date and time
    dt = datetime.datetime.now()
    body.append(text(dt.strftime('%Y-%m-%d'), 10))
    body.append(text(dt.strftime('%X'), 8))

    # battery life
    battery = "/sys/class/power_supply/BAT0"
    with open(f"{battery}/charge_now") as f:
        charge = int(f.read().strip())
    with open(f"{battery}/charge_full") as f:
        full_charge = int(f.read().strip())
    with open(f"{battery}/status") as f:
        state = f.read().strip().lower()
    body.append(text(f"{round(charge/full_charge*100)}% ({state})", 18))

    # volume
    get_volume = run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"]).split()
    volume = ""
    for field in get_volume:
        if field[-1] == "%":
            volume = field
    get_muted = run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"]).split()
    muted = ""
    if "yes" in get_muted:
        muted = " (muted)"
    body.append(text(f"{volume} volume{muted}", 18))
    return body

header = {"version": 1}

print(json.dumps(header))
print("[")

while True:
    print(json.dumps(get_body()))
    print(",", flush=True)
    time.sleep(1)
