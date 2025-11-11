#!/bin/sh
# Start-Script für Docker-Container

# Satis-Konfiguration
SATIS_CONFIG="${SATIS_CONFIG_PATH:-/build/config/satis.json}"
SATIS_OUTPUT="${SATIS_OUTPUT_PATH:-/build/output}"
FORCE_BUILD="${FORCE_BUILD_ON_STARTUP:-false}"

# AUTH_URL aus Umgebungsvariable lesen
# Wenn AUTH_URL nicht gesetzt ist, wird die Auth-Funktionalität deaktiviert
export AUTH_URL="${AUTH_URL:-}"

# Satis-Build ausführen, wenn nötig
if [ ! -f "${SATIS_OUTPUT}/packages.json" ] || [ "${FORCE_BUILD}" = "true" ]; then
    echo "Building Satis repository..."
    if [ ! -f "${SATIS_CONFIG}" ]; then
        echo "ERROR: Satis config file not found at ${SATIS_CONFIG}"
        exit 1
    fi
    /satis/bin/satis build "${SATIS_CONFIG}" "${SATIS_OUTPUT}"
    echo "Build completed. Files in ${SATIS_OUTPUT}:"
    ls -la "${SATIS_OUTPUT}" || true
else
    echo "Satis repository already built, skipping build..."
fi

# Verify output directory exists and has files
if [ ! -f "${SATIS_OUTPUT}/packages.json" ]; then
    echo "ERROR: packages.json not found in ${SATIS_OUTPUT}"
    echo "Directory contents:"
    ls -la "${SATIS_OUTPUT}" || true
    exit 1
fi

# Nginx root auf Satis output setzen
sed -i "s|root /usr/share/nginx/html;|root ${SATIS_OUTPUT};|g" /etc/nginx/conf.d/default.conf

# envsubst verwenden, um ${AUTH_URL} in default.conf zu ersetzen
envsubst '${AUTH_URL}' < /etc/nginx/conf.d/default.conf > /tmp/default.conf

# Wenn AUTH_URL leer ist, entferne die auth_request Direktiven
if [ -z "$AUTH_URL" ]; then
    # Entferne auth_request und auth_request_set Zeilen
    sed -i '/auth_request/d' /tmp/default.conf
    sed -i '/auth_request_set/d' /tmp/default.conf
    # Entferne den /auth location Block
    sed -i '/location = \/auth/,/^    }/d' /tmp/default.conf
fi

mv /tmp/default.conf /etc/nginx/conf.d/default.conf

# Webhook im Hintergrund starten
python3 /usr/local/bin/webhook.py &

# Nginx im Vordergrund starten
exec nginx -g 'daemon off;'

