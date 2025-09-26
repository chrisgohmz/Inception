#!/usr/bin/env bash
set -euo pipefail

: "${REDIS_PORT:=6379}"
: "${REDIS_DB:=0}"

REDIS_PASS=$(cat /run/secrets/redis_password)

mkdir -p /etc/redis /data

cat > /etc/redis/redis.conf << EOF
bind 0.0.0.0
port ${REDIS_PORT}
protected-mode yes
requirepass ${REDIS_PASS}
databases 16
timeout 0
tcp-keepalive 300
daemonize no
supervised no
dir /data
appendonly yes
appendfsync everysec
EOF

exec "$@"