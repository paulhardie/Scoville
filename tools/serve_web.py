#!/usr/bin/env python3
"""Serves build/web on the local network so a phone can open it.

No threads or isolation headers are needed (the export is single-threaded), so
this is a plain static server with three phone-testing changes:

- every response is `no-store`, so the phone never shows a stale build;
- `.wasm` has its proper type;
- Godot's loader refuses to start outside a secure context, and a phone reaching
  this Mac at http://192.168.x.x isn't one. While serving index.js (and only
  then, only here: build/web is untouched) the one `isSecureContext` pre-flight
  is answered "yes". Anything that truly needs HTTPS, like the PWA's service
  worker, simply isn't available on this address; host the build over HTTPS for
  that (docs/MOBILE.md).
"""
import argparse
import functools
import http.server
import os
import socket
import sys


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "text/javascript",
        ".webmanifest": "application/manifest+json",
    }

    def do_GET(self):
        if self.path.split("?")[0] == "/index.js":
            return self._serve_loader()
        return super().do_GET()

    def _serve_loader(self):
        # By path, not the working directory: a re-export deletes and recreates
        # the folder, and a server that had moved into it would be left in a void.
        with open(os.path.join(self.directory, "index.js"), "rb") as f:
            body = f.read()
        check = b"return window['isSecureContext'] === true;"
        if check not in body:
            # A different Godot's loader: serve it as it is rather than guess.
            sys.stderr.write("serve_web.py: the secure-context check wasn't found in index.js\n")
        body = body.replace(check, b"return true;")
        self.send_response(200)
        self.send_header("Content-Type", "text/javascript")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()

    def log_message(self, fmt, *args):
        # One line per page load, not one per file.
        if self.path in ("/", "/index.html"):
            sys.stderr.write("%s opened %s\n" % (self.address_string(), self.path))


def lan_address():
    """The address other devices on the network reach this machine at."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))  # no packet is sent; it just picks a route
        return s.getsockname()[0]
    except OSError:
        return None
    finally:
        s.close()


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--dir", default=os.path.join(os.path.dirname(__file__), "..", "build", "web"))
    ap.add_argument("--port", type=int, default=8060)
    args = ap.parse_args()
    root = os.path.abspath(args.dir)
    if not os.path.isfile(os.path.join(root, "index.html")):
        sys.exit("serve_web.py: no index.html in %s. Run: bash tools/export_web.sh" % root)
    try:
        server = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), functools.partial(Handler, directory=root))
    except OSError as e:
        sys.exit("serve_web.py: can't use port %d (%s). Try --port %d" % (args.port, e.strerror, args.port + 1))
    lan = lan_address()
    print("Serving %s" % root)
    print("  this Mac:   http://localhost:%d" % args.port)
    if lan:
        print("  your phone: http://%s:%d   (same Wi-Fi)" % (lan, args.port))
    else:
        print("  no network address found; connect to Wi-Fi to test on a phone")
    print("Ctrl-C to stop.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
