#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?}"
: "${DB_NAME:?}"
: "${DB_USER:?}"
: "${USER_EMAIL:?}"
: "${WP_URL:?}"
: "${WP_TITLE:?}"
: "${WP_ADMIN_USER:?}"
: "${WP_ADMIN_EMAIL:?}"
: "${WP_TABLE_PREFIX:?wp_}"
: "${REDIS_HOST:?}"
: "${REDIS_PORT:=6379}"
: "${REDIS_DB:=0}"
: "${SMTP_HOST:=mailpit}"; : "${SMTP_PORT:=1025}"; : "${DOMAIN:?}"

DB_PASS=$(cat /run/secrets/wp_db_password)
ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
USER_PASS=$(cat /run/secrets/wp_user_password)
REDIS_PASS=$(cat /run/secrets/redis_password)

cat > /etc/msmtprc << EOF
defaults
account mailpit
host ${SMTP_HOST}
port ${SMTP_PORT}
tls off
auth off
syslog on
from wordpress@${DOMAIN}
auto_from on
maildomain ${DOMAIN}
account default : mailpit
EOF
chmod 600 /etc/msmtprc
chown www-data:www-data /etc/msmtprc

if ! grep -q '^sendmail_path' /etc/php84/php.ini; then
    echo 'sendmail_path = "/usr/bin/msmtp -t -i -a mailpit -f wordpress@'${DOMAIN}'"' >> /etc/php84/php.ini
fi

if [ ! -f index.php ]; then
    echo "[wordpress] populating /var/www/html with WordPress files..."
    cp -R /tmp/wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html
fi

echo "[wordpress] waiting for database to be ready..."
for i in {1..60}; do
    if mariadb-admin ping -h "${DB_HOST}" -u"${DB_USER}" -p"${DB_PASS}" --silent >/dev/null 2>&1; then
        echo "[wordpress] database is ready."
        break
    fi
    sleep 1
done

if [ ! -f wp-config.php ]; then
    echo "[wordpress] configuring WordPress..."
    wp config create \
    --path=/var/www/html \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASS}" \
    --dbhost="${DB_HOST}" \
    --dbprefix="${WP_TABLE_PREFIX}" \
    --skip-check \
    --allow-root

    wp config shuffle-salts --allow-root
fi

if ! wp core is-installed --allow-root; then
    echo "[wordpress] installing WordPress..."
    wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root
fi

if wp user get "${DB_USER}" --field=ID --allow-root >/dev/null 2>&1; then
  wp user update "${DB_USER}" --user_pass="${USER_PASS}" --skip-email --allow-root
else
  wp user create "${DB_USER}" "${USER_EMAIL}" --role=author --user_pass="${USER_PASS}" --allow-root
fi

chown -R www-data:www-data /var/www/html

if ! wp plugin is-installed redis-cache --allow-root; then
    wp plugin install redis-cache --activate --allow-root
elif ! wp plugin is-active redis-cache --allow-root; then
    wp plugin activate redis-cache --allow-root
fi

wp config set WP_REDIS_HOST "${REDIS_HOST}" --type=constant --allow-root
wp config set WP_REDIS_PORT "${REDIS_PORT}" --type=constant --allow-root
wp config set WP_REDIS_DB "${REDIS_DB}" --type=constant --allow-root
wp config set WP_REDIS_PASSWORD "${REDIS_PASS}" --type=constant --allow-root

if ! wp redis status --field=status --allow-root 2>/dev/null | grep -qi 'Connected'; then
    wp redis enable --force --allow-root
fi

exec "$@"