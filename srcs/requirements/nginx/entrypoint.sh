#!/usr/bin/env bash
set -euo pipefail

: "${DOMAIN:?DOMAIN environment variable is required}"

if [[ ! -s "/etc/nginx/certs/${DOMAIN}.crt" ]] || [[ ! -s "/etc/nginx/certs/${DOMAIN}.key" ]]; then
    echo "Generating self-signed certificate for ${DOMAIN}..."
    openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
        -keyout /etc/nginx/certs/${DOMAIN}.key \
        -out /etc/nginx/certs/${DOMAIN}.crt \
        -subj "/CN=${DOMAIN}"
    echo "Self-signed certificate generated."
fi

envsubst '${DOMAIN}' \
    < /etc/nginx/templates/default.conf.template \
    > /etc/nginx/http.d/default.conf

exec "$@"