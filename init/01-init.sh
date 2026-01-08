#!/usr/bin/env bash
set -e

cd /var/www/html

# Esperar DB
echo "⏳ Esperando base de datos..."
until mysqladmin ping -h"${WORDPRESS_DB_HOST%:*}" -P"${WORDPRESS_DB_HOST#*:}" --silent; do
  sleep 2
done

# Si WP no está instalado, instalar
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  echo "🚀 Instalando WordPress..."

  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root

  wp language core install "${WP_LOCALE}" --activate --allow-root || true
  wp option update timezone_string "${WP_TIMEZONE}" --allow-root || true
  wp rewrite structure "/%postname%/" --hard --allow-root

  echo "🧩 Instalando plugins base..."
  # Elementor + elementos mínimos pro
  wp plugin install elementor --activate --allow-root

  # Plugins recomendados (livianos y útiles)
  wp plugin install wordpress-seo --activate --allow-root              # Yoast SEO
  wp plugin install wp-mail-smtp --activate --allow-root               # SMTP
  wp plugin install updraftplus --activate --allow-root                # Backups
  wp plugin install wordfence --activate --allow-root                  # Seguridad
  wp plugin install w3-total-cache --activate --allow-root || true     # Cache (depende del entorno)

  echo "🎨 Instalando tema Hello Elementor..."
  wp theme install hello-elementor --activate --allow-root

  echo "✅ Template Pixie listo."
else
  echo "✅ WordPress ya estaba instalado. No hago cambios."
fi