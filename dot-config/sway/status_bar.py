#!/usr/bin/env python3
import json, time, datetime, subprocess

VOLUME_SYMBOLS = [(0, "󰕿"), (1, "󰖀"), (50, "󰕾")]
BATTERY_SYMBOLS = [(i * 8, c) for i, c in enumerate("󰂎󰁺󰁻󰁼󰁽󰁾󰁿󰂀󰂁󰂂󰁹")]

def text(s, width):
    s = s.rjust(width)
    s = "".join([c if c.isprintable() else f'<span font_family="SymbolsNerdFontMono">{c}</span>' for c in s])
    return {"full_text": f" {s} ", "markup": "pango"}

def get_symbol(symbols, number):
    if isinstance(number, str):
        number = int("0" + "".join([c for c in number if c.isdigit()]))
    filtered = [(minimum, symbol) for minimum, symbol in symbols if number >= minimum]
    return max(filtered)[1]

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
    percent = round(charge / full_charge * 100)
    if state == "discharging":
        symbol = get_symbol(BATTERY_SYMBOLS, percent)
    else:
        symbol = "󰂄"
    body.append(text(f"{percent}% {symbol}", 5))

    # volume
    get_volume = run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"]).split()
    volume = ""
    for field in get_volume:
        if field[-1] == "%":
            volume = field
    get_muted = run(["pactl", "get-sink-mute", "@DEFAULT_SINK@"])
    if "yes" in get_muted:
        symbol = "󰝟"
    else:
        symbol = get_symbol(VOLUME_SYMBOLS, volume)
    body.append(text(f"{volume} {symbol}", 5))

    # microphone
    get_muted = run(["pactl", "get-source-mute", "@DEFAULT_SOURCE@"])
    if "yes" in get_muted:
        symbol = "󰍭"
    else:
        symbol = "󰍬"
    body.append(text(symbol, 1))
    return body

header = {"version": 1}

print(json.dumps(header))
print("[")

while True:
    print(json.dumps(get_body()))
    print(",", flush=True)
    time.sleep(1)
