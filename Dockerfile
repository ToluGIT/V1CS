FROM python:3.12-slim-bullseye
LABEL maintainer="research@example.com"
LABEL org.opencontainers.image.description="Vulnerable image with CVE-2024-0450 - FOR RESEARCH ONLY"

ENV DEBIAN_FRONTEND=noninteractive

# Install base packages
RUN apt-get update && apt-get install -y \
    apache2 \
    curl \
    wget \
    gcc \
    --no-install-recommends

# Create a vulnerable Python server (CVE-2024-0450)
WORKDIR /app
COPY vulnerable-app /app

# Create vulnerable Python server code
RUN echo 'from http.server import HTTPServer, BaseHTTPRequestHandler\n\
class VulnerableHandler(BaseHTTPRequestHandler):\n\
    def do_GET(self):\n\
        self.send_response(200)\n\
        self.send_header("Content-type", "text/html")\n\
        self.end_headers()\n\
        self.wfile.write(b"Vulnerable Server")\n\
\n\
def run(server_class=HTTPServer, handler_class=VulnerableHandler):\n\
    server_address = ("", 8000)\n\
    httpd = server_class(server_address, handler_class)\n\
    httpd.serve_forever()\n\
\n\
if __name__ == "__main__":\n\
    run()' > server.py

# Create test malware simulation
RUN echo "X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*" > eicar.com

EXPOSE 8000 80

CMD ["python3", "server.py"]
