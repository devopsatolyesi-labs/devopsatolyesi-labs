from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class CapstoneHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/healthz':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"HEALTHY"}')
        elif self.path == '/metrics':
            self.send_response(200)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'# HELP requests_total Total requests\nrequests_total 1\n')
        else:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"message":"Capstone Order Service v2.0.0"}')

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8000), CapstoneHandler)
    server.serve_forever()
