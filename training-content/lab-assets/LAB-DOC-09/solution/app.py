from http.server import HTTPServer, BaseHTTPRequestHandler
import urllib.request
import os

BACKEND_HOST = os.getenv("BACKEND_HOST", "backend-service")
BACKEND_PORT = os.getenv("BACKEND_PORT", "80")

class NetworkHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"UP"}\n')
            return

        target_url = f"http://{BACKEND_HOST}:{BACKEND_PORT}/"
        try:
            req = urllib.request.Request(target_url)
            with urllib.request.urlopen(req, timeout=3) as response:
                content = response.read().decode('utf-8')
                self.send_response(200)
                self.send_header('Content-type', 'text/plain; charset=utf-8')
                self.end_headers()
                self.wfile.write(f"Connected to backend ({BACKEND_HOST}): {content[:30]}...\n".encode('utf-8'))
        except Exception as e:
            self.send_response(502)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.end_headers()
            self.wfile.write(f"Failed to connect to backend ({BACKEND_HOST}): {str(e)}\n".encode('utf-8'))

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8080), NetworkHandler)
    print("Frontend serving on port 8080...")
    server.serve_forever()
