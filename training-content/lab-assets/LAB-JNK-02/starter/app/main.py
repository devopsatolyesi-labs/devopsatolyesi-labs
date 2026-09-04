from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class PaymentHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({"service": "secure-payment-service", "status": "active"}).encode())

if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8000), PaymentHandler)
    server.serve_forever()
