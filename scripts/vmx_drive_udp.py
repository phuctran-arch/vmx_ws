#!/usr/bin/env python3
"""Bounded manual drive commands for the VMX direct UDP low-level daemon.

Motor signs follow the previous four-wheel differential-drive bench log:
M0/M1 are the left side, M2/M3 the right side, with opposing raw signs.
Verify wheel positions and directions with the wheels lifted before driving.
"""

import argparse
import socket
import struct
import time


MAGIC = 0x43584D56
PORT = 15000
FORMAT_WITHOUT_CHECKSUM = "<IHHIQ4fI"


def fnv1a(data: bytes) -> int:
    value = 2166136261
    for byte in data:
        value = ((value ^ byte) * 16777619) & 0xFFFFFFFF
    return value


def packet(sequence: int, motors: tuple[float, float, float, float], enabled: bool) -> bytes:
    body = struct.pack(
        FORMAT_WITHOUT_CHECKSUM,
        MAGIC,
        1,
        44,
        sequence & 0xFFFFFFFF,
        time.time_ns(),
        *motors,
        int(enabled),
    )
    return body + struct.pack("<I", fnv1a(body))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("direction", choices=("forward", "backward", "left", "right", "stop"))
    parser.add_argument("--host", default="192.168.50.220", help="VMX IP on the connected network")
    parser.add_argument("--speed", type=float, default=0.16, help="raw Titan duty, default 0.16")
    parser.add_argument("--duration", type=float, default=0.7, help="motion time in seconds, default 0.7")
    args = parser.parse_args()

    if not 0.0 < args.speed <= 0.25:
        parser.error("--speed must be in (0, 0.25]")
    if not 0.0 < args.duration <= 3.0:
        parser.error("--duration must be in (0, 3.0]")

    # Forward: left ports positive, right ports negative. A turn is a spin in place.
    duty = args.speed
    motor_by_direction = {
        "forward": (duty, duty, -duty, -duty),
        "backward": (-duty, -duty, duty, duty),
        "left": (-duty, -duty, -duty, -duty),
        "right": (duty, duty, duty, duty),
        "stop": (0.0, 0.0, 0.0, 0.0),
    }
    motors = motor_by_direction[args.direction]
    sequence = time.monotonic_ns() & 0xFFFFFFFF
    address = (args.host, PORT)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def send(values: tuple[float, float, float, float], enabled: bool) -> None:
        nonlocal sequence
        sock.sendto(packet(sequence, values, enabled), address)
        sequence = (sequence + 1) & 0xFFFFFFFF

    try:
        if args.direction != "stop":
            end = time.monotonic() + args.duration
            while time.monotonic() < end:
                send(motors, True)
                time.sleep(0.1)
    finally:
        # A disable frame starts the daemon's zero/brake hold; repeat through
        # its 1-second hold window. The daemon also has a 0.30-second watchdog.
        try:
            for _ in range(12):
                send((0.0, 0.0, 0.0, 0.0), False)
                time.sleep(0.1)
        finally:
            sock.close()
    print(f"Sent {args.direction} command to {args.host}:{PORT}; final sequence {((sequence - 1) & 0xFFFFFFFF)}")


if __name__ == "__main__":
    main()
