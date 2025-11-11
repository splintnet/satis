# Einfaches Docker-Image mit Satis, Nginx, Auth-Proxy und Webhook
FROM composer/satis:latest as satis-base

# Nginx-Image als Basis für den finalen Container
FROM nginx:alpine

# Satis-Binärdateien vom Satis-Image kopieren
COPY --from=satis-base /satis /satis

# Python für Webhook und gettext für envsubst installieren
RUN apk add --no-cache python3 py3-pip gettext php81 php81-cli php81-json php81-mbstring php81-openssl php81-phar php81-zip php81-curl php81-dom php81-xml php81-xmlwriter php81-tokenizer php81-simplexml

# Nginx-Konfiguration kopieren
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Webhook-Script kopieren
COPY webhook.py /usr/local/bin/webhook.py
RUN chmod +x /usr/local/bin/webhook.py

# Satis-Verzeichnisse erstellen
RUN mkdir -p /build/output /build/config

# Webhook-Port freigeben (zusätzlich zu Port 80)
EXPOSE 80 8080

# Start-Script erstellen
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Nginx im Vordergrund starten und Webhook im Hintergrund
CMD ["/start.sh"]

