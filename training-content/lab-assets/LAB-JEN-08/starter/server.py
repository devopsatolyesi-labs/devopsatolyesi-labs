from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'{"status":"healthy"}')

if __name__ == '__main__':
    HTTPServer(('0.0.0.0', 5000), SimpleHandler).serve_forever()
