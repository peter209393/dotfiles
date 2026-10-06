#!/usr/bin/env python3
import json
import subprocess
import sys


def hyprctl(*args):
    return subprocess.run(["hyprctl", *args], capture_output=True, text=True).stdout


def ws_clients(ws):
    clients = json.loads(hyprctl("clients", "-j"))
    return [c for c in clients if c["workspace"]["id"] == ws and not c["floating"]]


def direction(anchor, win):
    dx = anchor["at"][0] - win["at"][0]
    dy = anchor["at"][1] - win["at"][1]
    if abs(dx) > abs(dy):
        return "r" if dx > 0 else "l"
    return "d" if dy > 0 else "u"


def stack_on(ws, active):
    wins = ws_clients(ws)
    anchor = next((c for c in wins if c["address"] == active), None)
    if anchor is None and wins:
        anchor = wins[0]
    if anchor is None:
        return
    if not anchor["grouped"]:
        hyprctl("dispatch", "focuswindow", "address:" + anchor["address"])
        hyprctl("dispatch", "togglegroup")
    for addr in [c["address"] for c in wins if c["address"] != anchor["address"]]:
        cur = ws_clients(ws)
        me = next((c for c in cur if c["address"] == addr), None)
        group = next((c for c in cur if c["address"] == anchor["address"]), None)
        if me is None or group is None or me["grouped"]:
            continue
        hyprctl("dispatch", "focuswindow", "address:" + addr)
        hyprctl("dispatch", "moveintogroup", direction(group, me))
    hyprctl("dispatch", "focuswindow", "address:" + anchor["address"])


def stack_off(ws, active):
    for c in ws_clients(ws):
        if c["grouped"]:
            hyprctl("dispatch", "focuswindow", "address:" + c["address"])
            hyprctl("dispatch", "moveoutofgroup")
    hyprctl("dispatch", "focuswindow", "address:" + active)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "on"
    ws = json.loads(hyprctl("activeworkspace", "-j"))["id"]
    active = json.loads(hyprctl("activewindow", "-j")).get("address", "")
    if mode == "on":
        stack_on(ws, active)
    else:
        stack_off(ws, active)


main()
