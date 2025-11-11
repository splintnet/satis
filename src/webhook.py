#!/usr/bin/env python3
"""
Einfacher Webhook-Service für Rebuild-Trigger
Läuft auf Port 8080 und akzeptiert POST-Requests mit Auth-Secret
"""

import os
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess

# Auth-Secret aus Umgebungsvariable lesen
AUTH_SECRET = os.environ.get('WEBHOOK_AUTH_SECRET', 'CHANGE_ME')
SATIS_CONFIG = os.environ.get('SATIS_CONFIG_PATH', '/build/config/satis.json')
SATIS_OUTPUT = os.environ.get('SATIS_OUTPUT_PATH', '/build/output')
REBUILD_COMMAND = os.environ.get('REBUILD_COMMAND', f'/satis/bin/satis build {SATIS_CONFIG} {SATIS_OUTPUT}')

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests to /webhook"""
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        # Auth-Secret aus Header prüfen
        auth_header = self.headers.get('X-Satis-Auth-Secret', '')

        if auth_header != AUTH_SECRET:
            self.send_response(401)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': 'Unauthorized'}).encode())
            return

        # Rebuild-Command ausführen
        try:
            result = subprocess.run(
                REBUILD_COMMAND.split(),
                capture_output=True,
                text=True,
                timeout=300
            )

            if result.returncode == 0:
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'status': 'success',
                    'message': 'Rebuild triggered',
                    'output': result.stdout
                }).encode())
            else:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({
                    'status': 'error',
                    'message': 'Rebuild failed',
                    'error': result.stderr
                }).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                'status': 'error',
                'message': str(e)
            }).encode())

    def do_GET(self):
        """Handle GET requests - Health check"""
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'ok'}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        """Override to use stderr for logging"""
        sys.stderr.write("%s - - [%s] %s\n" %
                        (self.address_string(),
                         self.log_date_time_string(),
                         format%args))

if __name__ == '__main__':
    port = int(os.environ.get('WEBHOOK_PORT', 8080))
    server = HTTPServer(('0.0.0.0', port), WebhookHandler)
    print(f'Webhook server starting on port {port}')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nShutting down webhook server')
        server.server_close()

