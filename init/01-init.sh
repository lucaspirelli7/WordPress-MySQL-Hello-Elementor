#!/bin/bash
set -u

# Allow some failures for checks, but be strict in general
# We don't use set -e globally to handle timeouts gracefully

WP_PATH="/var/www/html"
LOCK_FILE="${WP_PATH}/.wp_init_complete"

echo "==== [INIT] Starting Custom Initialization ===="

# 1. Wait for Database
echo "==== [INIT] Waiting for Database connection... ===="
MAX_RETRIES=30
count=0
until mysqladmin ping -h"${WORDPRESS_DB_HOST}" -P"${WORDPRESS_DB_PORT:-3306}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" --silent; do
  echo "    ...waiting for DB (${count}/${MAX_RETRIES})"
  sleep 2
  count=$((count+1))
  if [ $count -ge $MAX_RETRIES ]; then
    echo "==== [INIT] ❌ DB Timeout. Aborting init."
    exit 1
  fi
done
echo "==== [INIT] ✅ Database Connected."

# 2. Wait for WordPress Files (copied by official entrypoint)
echo "==== [INIT] Waiting for WordPress files... ===="
count=0
until [ -f "${WP_PATH}/wp-settings.php" ]; do
  echo "    ...waiting for WP files (${count}/${MAX_RETRIES})"
  sleep 4
  count=$((count+1))
  if [ $count -ge $MAX_RETRIES ]; then
    echo "==== [INIT] ❌ WP Files Timeout. Aborting init."
    exit 1
  fi
done
echo "==== [INIT] ✅ WP Files Detected."

# 3. Check if already initialized
if [ -f "$LOCK_FILE" ] || wp core is-installed --allow-root --path="$WP_PATH"; then
  echo "==== [INIT] ✅ WordPress is already installed. Skipping."
  exit 0
fi

# 4. Install WordPress
echo "==== [INIT] 🚀 Installing WordPress... ===="

# Determine URL if not set
if [ -z "${WP_URL:-}" ]; then
  if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    WP_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
  elif [ -n "${RAILWAY_STATIC_URL:-}" ]; then
    WP_URL="https://${RAILWAY_STATIC_URL}"
  else
    WP_URL="http://localhost:8000"
    echo "==== [INIT] ⚠️ No WP_URL provided. Defaulting to ${WP_URL}"
  fi
fi

# Install Core
if wp core install \
    --allow-root \
    --path="$WP_PATH" \
    --url="$WP_URL" \
    --title="${WP_TITLE:-My Blog}" \
    --admin_user="${WP_ADMIN_USER:-admin}" \
    --admin_password="${WP_ADMIN_PASS:-password}" \
    --admin_email="${WP_ADMIN_EMAIL:-admin@example.com}"; then
    
    echo "==== [INIT] ✅ Core Installed."
else
    echo "==== [INIT] ❌ Core Install Failed."
    exit 1
fi

# 5. Configuration & Plugins
echo "==== [INIT] Configuring Settings & Plugins..."
wp language core install "${WP_LOCALE:-es_ES}" --activate --allow-root --path="$WP_PATH" || true
wp option update timezone_string "${WP_TIMEZONE:-America/Argentina/Buenos_Aires}" --allow-root --path="$WP_PATH" || true
wp rewrite structure "/%postname%/" --hard --allow-root --path="$WP_PATH" || true

echo "==== [INIT] Installing Elementor & Hello Theme..."
wp theme install hello-elementor --activate --allow-root --path="$WP_PATH" || true
wp plugin install elementor --activate --allow-root --path="$WP_PATH" || true

# Mark as done
touch "$LOCK_FILE"
echo "==== [INIT] ✅ Initialization Complete. ===="
