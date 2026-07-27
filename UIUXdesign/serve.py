#!/usr/bin/env python3
"""Serve all five Zenno UI/UX design prototypes, each on its own port.

Run:  python3 UIUXdesign/serve.py
Then open:
    http://localhost:8001  -> Aurora   (premium glass dark)
    http://localhost:8002  -> Atelier  (warm light study-desk)
    http://localhost:8003  -> Zen      (ultra-minimal calm)
    http://localhost:8004  -> Bold     (neo-brutalist pop)
    http://localhost:8005  -> Command  (pro / dense)

Ctrl-C to stop them all.
"""
import functools
import http.server
import os
import socketserver
import threading

BASE = os.path.dirname(os.path.abspath(__file__))

DESIGNS = {
    8001: "01-aurora",
    8002: "02-atelier",
    8003: "03-zen",
    8004: "04-bold",
    8005: "05-command",
}


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):  # silence per-request noise
        pass


def serve(port, folder):
    directory = os.path.join(BASE, folder)
    handler = functools.partial(_QuietHandler, directory=directory)
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", port), handler) as httpd:
        httpd.serve_forever()


def main():
    items = list(DESIGNS.items())
    for port, folder in items:
        label = folder.split("-", 1)[1]
        print(f"  http://localhost:{port}  ->  {label}")
    print("\nServing all five designs. Press Ctrl-C to stop.\n")
    # Run all but the last in background threads; the last blocks the main thread.
    for port, folder in items[:-1]:
        threading.Thread(target=serve, args=(port, folder), daemon=True).start()
    last_port, last_folder = items[-1]
    try:
        serve(last_port, last_folder)
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    main()
