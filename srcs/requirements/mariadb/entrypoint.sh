#!/usr/bin/env bash
set -euo pipefail

ROOT_PASS="$(cat /run/secrets/mariadb_root_password)"
: "${WP_DB_NAME:?}"; : "${WP_DB_USER:?}"
WP_DB_PASS="$(cat /run/secrets/wp_db_password)"

# Ensure runtime dirs/ownership
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

BOOTSTRAP=0
if [ ! -d /var/lib/mysql/mysql ]; then
  echo "[mariadb] initializing datadir..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql \
    --skip-test-db --auth-root-authentication-method=normal
  BOOTSTRAP=1
fi

echo "[mariadb] starting temporary server (socket-only)..."
mysqld --user=mysql --datadir=/var/lib/mysql \
       --skip-networking=1 \
       --socket=/run/mysqld/mysqld.sock &
pid="$!"

# Wait for socket
for i in {1..60}; do
  if mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock ping --silent; then
    break
  fi
  sleep 1
done

# First-run root setup
if [ "$BOOTSTRAP" = "1" ]; then
  echo "[mariadb] securing root@localhost..."
  mysql --protocol=socket --socket=/run/mysqld/mysqld.sock <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
DELETE FROM mysql.user WHERE user='';
FLUSH PRIVILEGES;
SQL
fi

# ALWAYS ensure WP DB/user exist AND password matches the secret
echo "[mariadb] ensuring schema and user..."
mysql -uroot -p"${ROOT_PASS}" --protocol=socket --socket=/run/mysqld/mysqld.sock <<SQL
CREATE DATABASE IF NOT EXISTS \`${WP_DB_NAME}\`
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${WP_DB_USER}'@'%' IDENTIFIED BY '${WP_DB_PASS}';
ALTER USER '${WP_DB_USER}'@'%' IDENTIFIED BY '${WP_DB_PASS}';
GRANT ALL PRIVILEGES ON \`${WP_DB_NAME}\`.* TO '${WP_DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

echo "[mariadb] stopping temporary server..."
mysqladmin --protocol=socket --socket=/run/mysqld/mysqld.sock -p"${ROOT_PASS}" shutdown
wait "${pid}"

echo "[mariadb] starting full server..."
exec "$@"   # e.g., mariadbd --user=mysql --bind-address=0.0.0.0
