#!/bin/sh

apk add --no-cache curl >/dev/null 2>&1

CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

restart_nginx() {
    curl -s --unix-socket /var/run/docker.sock -X POST http://localhost/containers/nginx/restart
}

if [ ! -f "$CERT_PATH" ]; then
    echo "=== Creating dummy cert ==="
    mkdir -p /etc/letsencrypt/live/$DOMAIN
    openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
        -keyout $KEY_PATH -out $CERT_PATH -subj "/CN=$DOMAIN"
fi

echo "=== Waiting for nginx ==="
sleep 10

if ! openssl x509 -issuer -noout -in "$CERT_PATH" 2>/dev/null | grep -q "Let's Encrypt"; then
    echo "=== Requesting Let's Encrypt cert ==="
    rm -rf /etc/letsencrypt/live/$DOMAIN /etc/letsencrypt/archive/$DOMAIN /etc/letsencrypt/renewal/$DOMAIN.conf
    certbot certonly --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        --cert-name $DOMAIN \
        -d $DOMAIN -d www.$DOMAIN && restart_nginx
fi

echo "=== Starting renewal loop ==="
trap exit TERM
while :; do
    certbot renew && restart_nginx
    sleep 12h &
    wait $!
done
