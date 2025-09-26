#!/usr/bin/env bash
set -euo pipefail

: "${FTP_USER:-wpftp}"
: "${FTP_UID:-82}"
: "${FTP_GID:-82}"
: "${FTP_PASV_MIN:-30000}"
: "${FTP_PASV_MAX:-30100}"

FTP_PASS=$(cat /run/secrets/ftp_password)

SITE_DIR="/var/www/html"
CONF_DIR="/etc/vsftpd"

if ! getent group "${FTP_GID}" > /dev/null 2>&1 && ! getent group "${FTP_USER}" > /dev/null 2>&1; then
    addgroup -S -g "${FTP_GID}" www-data || true
fi
if ! id -u "${FTP_USER}" > /dev/null 2>&1; then
    adduser -S -D -H -u "${FTP_UID}" -G "$(getent group ${FTP_GID} | cut -d: -f1 || echo www-data)" -s /sbin/nologin "${FTP_USER}"
fi
echo "${FTP_USER}:${FTP_PASS}" | chpasswd

usermod -d "${SITE_DIR}" "${FTP_USER}" || true

mkdir -p "${CONF_DIR}"
cat > "${CONF_DIR}/vsftpd.conf" << EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
use_localtime=YES
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=${SITE_DIR}
userlist_enable=YES
userlist_deny=NO
userlist_file=${CONF_DIR}/user_list
pasv_enable=YES
pasv_min_port=${FTP_PASV_MIN}
pasv_max_port=${FTP_PASV_MAX}
xferlog_enable=YES
xferlog_std_format=NO
log_ftp_protocol=YES
pam_service_name=vsftpd
seccomp_sandbox=NO
EOF

echo "${FTP_USER}" > "${CONF_DIR}/user_list"

mkdir -p "${SITE_DIR}"

echo "[ftp] starting vsftpd for user ${FTP_USER} (uid: ${FTP_UID}, gid: ${FTP_GID})"
exec "$@"