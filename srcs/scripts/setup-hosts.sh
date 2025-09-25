#!/usr/bin/env bash
set -euo pipefail
: "${DOMAIN:?DOMAIN env is required}"

IP="127.0.0.1"
LINE="${IP} ${DOMAIN}"

if grep -qE "^[# ]*${IP}[[:space:]]+${DOMAIN}$" /etc/hosts; then
    echo "[setup-hosts] Entry for ${DOMAIN} already exists in /etc/hosts"
else
    echo "[setup-hosts] Adding entry for ${DOMAIN} to /etc/hosts"
    sudo sh -c "printf '%s\n' '${LINE}' >> /etc/hosts"
fi