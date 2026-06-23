#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import signal
import subprocess
import sys
import time
from pathlib import Path
from typing import NoReturn

CFG_DIR = Path("/var/lib/fan")
CFG_FILE = CFG_DIR / "config.json"
DEFAULT_FILE = Path("/etc/fan/default-config.json")

DEF = {
    "TEMP_MIN": 35.0,
    "TEMP_MAX": 70.0,
    "MIN_DUTY": 0.40,
    "PWM_PIN": 18,
    "PWM_FREQUENCY": 250,
    "CHECK_INTERVAL": 5.0,
    "MIN_CHANGE_INTERVAL": 60.0,
    "MODE": "auto",
    "MANUAL_DUTY": 0,
}

DUTY_STEP = 10


def _load() -> dict:
    base = DEF.copy()

    if DEFAULT_FILE.exists():
        base |= json.loads(DEFAULT_FILE.read_text())

    if CFG_FILE.exists():
        runtime = json.loads(CFG_FILE.read_text())
        base["MODE"] = runtime.get("MODE", base["MODE"])
        base["MANUAL_DUTY"] = runtime.get("MANUAL_DUTY", base["MANUAL_DUTY"])

    return base


def _save(c: dict) -> None:
    CFG_DIR.mkdir(parents=True, exist_ok=True)

    runtime = {
        "MODE": c["MODE"],
        "MANUAL_DUTY": c["MANUAL_DUTY"],
    }

    CFG_FILE.write_text(json.dumps(runtime, indent=2))


def cpu_temp() -> float:
    return int(Path("/sys/class/thermal/thermal_zone0/temp").read_text()) / 1000


def auto_pct(t: float, c: dict) -> int:
    if t < c["TEMP_MIN"]:
        return 0

    if t >= c["TEMP_MAX"]:
        return 100

    span = c["TEMP_MAX"] - c["TEMP_MIN"]
    frac = c["MIN_DUTY"] + (1 - c["MIN_DUTY"]) * (t - c["TEMP_MIN"]) / span
    return round(frac * 100)


def daemon() -> NoReturn:
    import lgpio

    cfg = _load()
    pwm_pin = int(cfg["PWM_PIN"])
    pwm_frequency = int(cfg["PWM_FREQUENCY"])

    h = lgpio.gpiochip_open(0)
    lgpio.gpio_claim_output(h, pwm_pin, 0)

    def set_fan(pct: int) -> None:
        pct = max(0, min(100, int(pct)))
        lgpio.tx_pwm(h, pwm_pin, pwm_frequency, pct)

    def stop(*_) -> NoReturn:
        set_fan(0)
        lgpio.gpiochip_close(h)
        sys.exit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    state = {"force": False}
    signal.signal(signal.SIGUSR1, lambda *_: state.__setitem__("force", True))

    last = -1
    last_change = 0.0
    last_mode = "auto"

    try:
        while True:
            cfg = _load()

            pct = (
                cfg["MANUAL_DUTY"]
                if cfg["MODE"] == "manual"
                else auto_pct(cpu_temp(), cfg)
            )

            now = time.time()

            if cfg["MODE"] != last_mode or state["force"]:
                set_fan(pct)
                last = pct
                last_change = now
                last_mode = cfg["MODE"]
                state["force"] = False
            elif cfg["MODE"] == "manual" and pct != last:
                set_fan(pct)
                last = pct
            elif (
                cfg["MODE"] == "auto"
                and now - last_change >= cfg["MIN_CHANGE_INTERVAL"]
                and abs(pct - last) >= DUTY_STEP
            ):
                set_fan(pct)
                last = pct
                last_change = now

            time.sleep(cfg["CHECK_INTERVAL"])
    finally:
        set_fan(0)
        lgpio.gpiochip_close(h)


def status(cfg: dict) -> None:
    t = cpu_temp()
    pct = cfg["MANUAL_DUTY"] if cfg["MODE"] == "manual" else auto_pct(t, cfg)
    print(f"CPU {t:.1f} °C | Fan {pct}% | Mode {cfg['MODE']}")


def notify() -> None:
    subprocess.run(
        ["pkill", "-SIGUSR1", "-f", "fan --daemon"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def main() -> None:
    p = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    p.add_argument("percent", nargs="?", type=int, help="manual speed 0-100 %%")
    p.add_argument("-r", "--reset", action="store_true", help="back to auto mode")
    p.add_argument("-m", metavar="TEMP_MIN", type=float)
    p.add_argument("-x", metavar="TEMP_MAX", type=float)
    p.add_argument("-d", metavar="MIN_DUTY", type=float)
    p.add_argument("-i", metavar="SEC", type=float)
    p.add_argument("-s", "--settle", metavar="SEC", type=float)
    p.add_argument("--daemon", action="store_true", help=argparse.SUPPRESS)

    a = p.parse_args()
    cfg = _load()
    changed = False

    if a.daemon:
        daemon()

    if a.percent is not None:
        if not 0 <= a.percent <= 100:
            p.error("percent 0-100")
        cfg["MODE"] = "manual"
        cfg["MANUAL_DUTY"] = a.percent
        changed = True

    if a.reset:
        cfg["MODE"] = "auto"
        changed = True

    if a.m is not None:
        cfg["TEMP_MIN"] = a.m
        changed = True

    if a.x is not None:
        cfg["TEMP_MAX"] = a.x
        changed = True

    if a.d is not None:
        if not 0 <= a.d <= 1:
            p.error("MIN_DUTY 0-1")
        cfg["MIN_DUTY"] = a.d
        changed = True

    if a.i and a.i > 0:
        cfg["CHECK_INTERVAL"] = a.i
        changed = True

    if a.settle and a.settle > 0:
        cfg["MIN_CHANGE_INTERVAL"] = a.settle
        changed = True

    if changed:
        _save(cfg)
        notify()
    else:
        status(cfg)


if __name__ == "__main__":
    main()
