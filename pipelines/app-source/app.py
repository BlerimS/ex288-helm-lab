from http.server import BaseHTTPRequestHandler, HTTPServer
import json

BOOKS = [
    {"id": 1, "title": "OpenShift in Action", "author": "EX288 Lab"},
    {"id": 2, "title": "Tekton Pipelines", "author": "Red Hat"},
]


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ("/", "/api/books", "/health"):
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            body = {"books": BOOKS} if self.path != "/health" else {"status": "ok"}
            self.wfile.write(json.dumps(body).encode())
        else:
            self.send_response(404)
            self.end_headers()


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
