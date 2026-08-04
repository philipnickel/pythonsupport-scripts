# Tiny static file server for the Windows test container.
# Serves /repo at http://127.0.0.1:8000 with text/* MIME types so that
# PowerShell's Invoke-WebRequest returns .Content as a string (like
# raw.githubusercontent.com does) instead of a byte array.
import http.server
import functools


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".ps1": "text/plain; charset=utf-8",
        ".sh": "text/plain; charset=utf-8",
        ".txt": "text/plain; charset=utf-8",
        ".json": "application/json; charset=utf-8",
    }

    def log_message(self, *args):
        pass  # keep container logs quiet


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(
        ("127.0.0.1", 8000), functools.partial(Handler, directory="/repo")
    ).serve_forever()
