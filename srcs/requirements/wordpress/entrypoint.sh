#!/usr/bin/env bash
set -euo pipefail

: "${DB_HOST:?}"
: "${DB_NAME:?}"
: "${DB_USER:?}"
: "${WP_URL:?}"
: "${WP_TITLE:?}"
: "${WP_ADMIN_USER:?}"
: "${WP_ADMIN_EMAIL:?}"
: "${WP_TABLE_PREFIX:?wp_}"

DB_PASS=$(cat /run/secrets/wp_db_password)
ADMIN_PASS=$(cat /run/secrets/wp_admin_password)
USER_PASS=$(cat /run/secrets/wp_user_password)

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

    wp user create "${DB_USER}" "${WP_ADMIN_EMAIL/.*/+user@dummy}" \
    --user_pass="${USER_PASS}" \
    --role=author \
    --allow-root || true
fi

chown -R www-data:www-data /var/www/html

exec "$@"