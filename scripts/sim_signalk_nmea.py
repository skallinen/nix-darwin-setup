#!/usr/bin/env python3
"""Emit synthetic NMEA0183 data to Signal K over UDP.

Usage:
  ./scripts/sim_signalk_nmea.py --host 127.0.0.1 --port 10110
"""

import argparse
import math
import random
import socket
import time
from datetime import datetime, timezone


def checksum(sentence_body: str) -> str:
    value = 0
    for ch in sentence_body:
        value ^= ord(ch)
    return f"{value:02X}"


def nmea(sentence_body: str) -> str:
    return f"${sentence_body}*{checksum(sentence_body)}"


def to_lat(lat: float):
    hemi = "N" if lat >= 0 else "S"
    abs_lat = abs(lat)
    deg = int(abs_lat)
    minutes = (abs_lat - deg) * 60
    return f"{deg:02d}{minutes:06.3f}", hemi


def to_lon(lon: float):
    hemi = "E" if lon >= 0 else "W"
    abs_lon = abs(lon)
    deg = int(abs_lon)
    minutes = (abs_lon - deg) * 60
    return f"{deg:03d}{minutes:06.3f}", hemi


def build_rmc(lat: float, lon: float, sog_kn: float, cog_deg: float, now: datetime):
    lat_s, lat_h = to_lat(lat)
    lon_s, lon_h = to_lon(lon)
    t = now.strftime("%H%M%S.00")
    d = now.strftime("%d%m%y")
    body = (
        f"GPRMC,{t},A,{lat_s},{lat_h},{lon_s},{lon_h},"
        f"{sog_kn:.1f},{cog_deg:.1f},{d},,,A"
    )
    return nmea(body)


def build_mwv(angle_true_deg: float, wind_kn: float):
    body = f"IIMWV,{angle_true_deg:.1f},R,{wind_kn:.1f},N,A"
    return nmea(body)


def build_dpt(depth_m: float):
    body = f"IIDPT,{depth_m:.1f},0.0"
    return nmea(body)


def advance_position(lat: float, lon: float, sog_kn: float, cog_deg: float, dt_sec: float):
    speed_mps = sog_kn * 0.514444
    distance_m = speed_mps * dt_sec
    heading = math.radians(cog_deg)
    dn = distance_m * math.cos(heading)
    de = distance_m * math.sin(heading)
    dlat = dn / 111_320.0
    dlon = de / (111_320.0 * max(math.cos(math.radians(lat)), 1e-6))
    return lat + dlat, lon + dlon


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=10110)
    parser.add_argument("--hz", type=float, default=1.0, help="Update frequency")
    parser.add_argument("--lat", type=float, default=60.1699, help="Start latitude")
    parser.add_argument("--lon", type=float, default=24.9384, help="Start longitude")
    parser.add_argument("--sog", type=float, default=5.5, help="Speed over ground in knots")
    parser.add_argument("--cog", type=float, default=95.0, help="Course over ground in degrees")
    args = parser.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    lat = args.lat
    lon = args.lon
    interval = 1.0 / max(args.hz, 0.1)
    t = 0

    print(f"Sending NMEA to udp://{args.host}:{args.port} every {interval:.2f}s")
    print("Press Ctrl+C to stop.")
    try:
        while True:
            now = datetime.now(timezone.utc)
            sog = args.sog + 0.4 * math.sin(t / 20.0)
            cog = (args.cog + 3.0 * math.sin(t / 30.0)) % 360
            awa = 35 + 15 * math.sin(t / 15.0)
            tws = 12 + 2 * math.sin(t / 12.0)
            depth = 9.5 + 0.8 * math.sin(t / 40.0) + random.uniform(-0.1, 0.1)

            sentences = [
                build_rmc(lat, lon, sog, cog, now),
                build_mwv(awa, tws),
                build_dpt(depth),
            ]
            for s in sentences:
                sock.sendto((s + "\r\n").encode("ascii"), (args.host, args.port))
                print(s)

            lat, lon = advance_position(lat, lon, sog, cog, interval)
            t += 1
            time.sleep(interval)
    except KeyboardInterrupt:
        pass
    finally:
        sock.close()


if __name__ == "__main__":
    main()
