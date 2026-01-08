#!/bin/bash
set -euo pipefail

# ===== Requeridos DB =====
: "${WORDPRESS_DB_HOST:?Missing WORDPRESS_DB_HOST}"
: "${WORDPRESS_DB_NAME:?Missing WORDPRESS_DB_NAME}"
: "${WORDPRESS_DB_USER:?Missing WORDPRESS_DB_USER}"
: "${WORDPRESS_DB_PASSWORD:?Missing WORDPRESS_DB_PASSWORD}"

WP_PATH="/var/www/html"
MARKER_FILE="${WP_PATH}/wp-content/.pixie-init-done"

# Parse host:port
DB_HOST="${WORDPRESS_DB_HOST%:*}"
DB_PORT="${WORDPRESS_DB_HOST##*:}"
if [ "$DB_HOST" = "$DB_PORT" ]; then DB_PORT="3306"; fi

echo "Waiting for DB TCP ${DB_HOST}:${DB_PORT}..."
for i in $(seq 1 60); do
  (echo >"/dev/tcp/${DB_HOST}/${DB_PORT}") >/dev/null 2>&1 && break
  sleep 2
done

# ===== Esperar a que WP se copie (entrypoint original) =====
echo "⏳ Esperando archivos de WordPress en ${WP_PATH}..."
for i in $(seq 1 60); do
  if [ -f "${WP_PATH}/wp-settings.php" ]; then
    echo "✅ Archivos de WP detectados."
    break
  fi
  sleep 2
done

if [ ! -f "${WP_PATH}/wp-settings.php" ]; then
  echo "❌ Timeout esperando archivos de WP. Abortando init."
  exit 1
fi

# ===== Variables de setup =====
# Si no definís WP_URL, intentamos armarla desde Railway automáticamente
# (si tenés dominio público en Railway)
if [ -z "${WP_URL:-}" ]; then
  if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    WP_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
  elif [ -n "${RAILWAY_STATIC_URL:-}" ]; then
    WP_URL="${RAILWAY_STATIC_URL}"
  else
    echo "ERROR: Missing WP_URL and no Railway domain found (RAILWAY_PUBLIC_DOMAIN/RAILWAY_STATIC_URL)."
    exit 1
  fi
fi

WP_TITLE="${WP_TITLE:-My Pixie WordPress}"
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASS="${WP_ADMIN_PASS:-admin123}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"
WP_LOCALE="${WP_LOCALE:-es_ES}"
WP_TIMEZONE="${WP_TIMEZONE:-America/Argentina/Buenos_Aires}"

# ===== Evitar re-ejecutar init si ya se hizo =====
if [ -f "$MARKER_FILE" ]; then
  echo "Init marker exists. Skipping."
  exit 0
fi

# ===== Asegurar wp-config.php (clave para que wp funcione antes del entrypoint oficial) =====
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
  echo "wp-config.php not found. Creating via WP-CLI..."
  wp config create \
    --allow-root \
    --path="$WP_PATH" \
    --dbname="$WORDPRESS_DB_NAME" \
    --dbuser="$WORDPRESS_DB_USER" \
    --dbpass="$WORDPRESS_DB_PASSWORD" \
    --dbhost="$WORDPRESS_DB_HOST" \
    --skip-check \
    --force

  # Ajustes útiles “base”
  wp config set WP_DEBUG false --allow-root --path="$WP_PATH" --type=constant
  wp config set FS_METHOD direct --allow-root --path="$WP_PATH" --type=constant
fi

# ===== Instalar WP si no está =====
if wp core is-installed --allow-root --path="$WP_PATH"; then
  echo "WP already installed."
else
  echo "Installing WordPress..."
  wp core install \
    --allow-root \
    --path="$WP_PATH" \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL"
fi

echo "Config basics..."
wp language core install "$WP_LOCALE" --activate --allow-root --path="$WP_PATH"
wp option update timezone_string "$WP_TIMEZONE" --allow-root --path="$WP_PATH"

echo "Installing theme + plugins..."
wp theme install hello-elementor --activate --allow-root --path="$WP_PATH"
wp plugin install elementor --activate --allow-root --path="$WP_PATH"

# Plugins base (ojo: Wordfence puede consumir bastante)
wp plugin install wp-mail-smtp --activate --allow-root --path="$WP_PATH"
wp plugin install autoptimize --activate --allow-root --path="$WP_PATH"
wp plugin install updraftplus --activate --allow-root --path="$WP_PATH"
wp plugin install wordfence --activate --allow-root --path="$WP_PATH"

# Marker para no repetir
mkdir -p "$(dirname "$MARKER_FILE")"
touch "$MARKER_FILE"

echo "Init done ✅"
