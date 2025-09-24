#!/usr/bin/env bash
set -euo pipefail
LOGIN=$(grep '^LOGIN=' srcs/.env | cut -d '=' -f2)
SEC_DIR=/home/${LOGIN}/data/secrets
mkdir -p ${SEC_DIR}
umask 077

declare -A S=(
    [mariadb_root_password]=`openssl rand -base64 12`
    [wp_db_password]=`openssl rand -base64 12`
    [wp_admin_password]=`openssl rand -base64 12`
    [wp_user_password]=`openssl rand -base64 12`
)

for k in "${!S[@]}"; do
    f="${SEC_DIR}/${k}"
    if [ ! -s "${f}" ]; then
        echo "${S[$k]}" > "${f}"
        chmod 400 "${f}"
        echo "[mksecrets] created secret ${k}"
    else
        echo "[mksecrets] secret ${k} already exists, skipping"
    fi
done