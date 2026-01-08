#!/bin/bash
set -e

: "${WORDPRESS_DB_HOST:?Missing WORDPRESS_DB_HOST}"
: "${WORDPRESS_DB_NAME:?Missing WORDPRESS_DB_NAME}"
: "${WORDPRESS_DB_USER:?Missing WORDPRESS_DB_USER}"
: "${WORDPRESS_DB_PASSWORD:?Missing WORDPRESS_DB_PASSWORD}"

# Parse host:port
DB_HOST="${WORDPRESS_DB_HOST%:*}"
DB_PORT="${WORDPRESS_DB_HOST##*:}"
if [ "$DB_HOST" = "$DB_PORT" ]; then DB_PORT="3306"; fi

echo "Waiting for DB at ${DB_HOST}:${DB_PORT}..."
for i in {1..60}; do
  (echo > /dev/tcp/$DB_HOST/$DB_PORT) >/dev/null 2>&1 && break
  sleep 2
done

# Si WP ya está instalado, salimos
if wp core is-installed --allow-root --path=/var/www/html; then
  echo "WP already installed. Skipping init."
  exit 0
fi

# Variables “de setup”
: "${WP_URL:?Missing WP_URL}"
: "${WP_TITLE:=My Pixie WordPress}"
: "${WP_ADMIN_USER:=admin}"
: "${WP_ADMIN_PASS:=admin123}"
: "${WP_ADMIN_EMAIL:=admin@example.com}"
: "${WP_LOCALE:=es_ES}"
: "${WP_TIMEZONE:=America/Argentina/Buenos_Aires}"

echo "Installing WordPress..."
wp core install \
  --allow-root \
  --path=/var/www/html \
  --url="$WP_URL" \
  --title="$WP_TITLE" \
  --admin_user="$WP_ADMIN_USER" \
  --admin_password="$WP_ADMIN_PASS" \
  --admin_email="$WP_ADMIN_EMAIL"

echo "Config basics..."
wp language core install "$WP_LOCALE" --activate --allow-root --path=/var/www/html
wp option update timezone_string "$WP_TIMEZONE" --allow-root --path=/var/www/html

echo "Installing theme + plugins..."
wp theme install hello-elementor --activate --allow-root --path=/var/www/html

# Elementor (ojo: Elementor Pro NO se puede por repo público sin licencia)
wp plugin install elementor --activate --allow-root --path=/var/www/html

# Plugins sugeridos “Pixie base”
wp plugin install wp-mail-smtp --activate --allow-root --path=/var/www/html
wp plugin install wordfence --activate --allow-root --path=/var/www/html
wp plugin install autoptimize --activate --allow-root --path=/var/www/html
wp plugin install updraftplus --activate --allow-root --path=/var/www/html

echo "Init done."
