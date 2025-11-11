# Einfaches Docker-Image mit Satis, Nginx, Auth-Proxy und Webhook
# Basierend auf dem offiziellen Satis Dockerfile: https://github.com/composer/satis/blob/main/Dockerfile
FROM composer/satis:latest

# Nginx und zusätzliche Tools installieren
RUN set -eux ; \
  apk add --no-cache --upgrade \
    nginx \
    python3 \
    py3-pip \
    gettext

# Nginx-Konfiguration kopieren
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Webhook-Script kopieren
COPY webhook.py /usr/local/bin/webhook.py
RUN chmod +x /usr/local/bin/webhook.py

# Satis-Verzeichnisse erstellen (falls nicht vorhanden)
WORKDIR /build
RUN mkdir -p /build/output /build/config

# Webhook-Port freigeben (zusätzlich zu Port 80)
EXPOSE 80 8080

# Start-Script erstellen
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Nginx im Vordergrund starten und Webhook im Hintergrund
CMD ["/start.sh"]

