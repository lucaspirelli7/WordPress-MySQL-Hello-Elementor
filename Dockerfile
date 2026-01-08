FROM wordpress:php8.2-apache

# 1. Install dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    less \
    unzip \
    && rm -rf /var/lib/apt/lists/* \
    && a2dismod mpm_event mpm_worker || true \
    && a2enmod mpm_prefork

# 2. Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# 3. Create Custom Entrypoint (INLINE to avoid Windows CRLF issues)
RUN echo '#!/bin/bash\n\
    set -e\n\
    \n\
    echo "🚀 [ENTRY] Starting WordPress..."\n\
    \n\
    # Run init script in background\n\
    (\n\
    sleep 10\n\
    /usr/local/bin/init-wp.sh\n\
    echo "✅ [INIT] Background task finished"\n\
    ) > /proc/1/fd/1 2>/proc/1/fd/2 &\n\
    \n\
    # Run official entrypoint\n\
    exec docker-entrypoint.sh "$@"\n\
    ' > /usr/local/bin/custom-entrypoint.sh && chmod +x /usr/local/bin/custom-entrypoint.sh

# 4. Create Init Script (INLINE)
RUN echo '#!/bin/bash\n\
    set -u\n\
    \n\
    echo "🔎 [INIT] Waiting for DB..."\n\
    until mysqladmin ping -h"$WORDPRESS_DB_HOST" -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent; do\n\
    echo "   ...db not ready"\n\
    sleep 5\n\
    done\n\
    \n\
    echo "🔎 [INIT] Waiting for WP Core files..."\n\
    until [ -f /var/www/html/wp-settings.php ]; do\n\
    echo "   ...files not copied yet"\n\
    sleep 5\n\
    done\n\
    \n\
    if wp core is-installed --allow-root --path=/var/www/html; then\n\
    echo "✅ [INIT] Already installed"\n\
    exit 0\n\
    fi\n\
    \n\
    echo "⚙️ [INIT] Installing..."\n\
    wp core install --allow-root --path=/var/www/html --url="${WP_URL:-http://localhost}" --title="${WP_TITLE:-Pixie}" --admin_user="${WP_ADMIN_USER:-admin}" --admin_password="${WP_ADMIN_PASS:-admin123}" --admin_email="${WP_ADMIN_EMAIL:-admin@test.com}" --skip-email\n\
    wp theme install hello-elementor --activate --allow-root --path=/var/www/html\n\
    wp plugin install elementor --activate --allow-root --path=/var/www/html\n\
    echo "✅ [INIT] Complete"\n\
    ' > /usr/local/bin/init-wp.sh && chmod +x /usr/local/bin/init-wp.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]
