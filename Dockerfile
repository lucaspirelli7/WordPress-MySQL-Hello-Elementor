FROM wordpress:php8.2-apache

# 1. Install dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    less \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# 3. Neuter the official entrypoint
# This replaces the final 'exec "$@"' with an echo, so it runs setup but doesn't start Apache.
RUN sed -i 's/^exec "$@"/echo "Base entrypoint finished running"/' /usr/local/bin/docker-entrypoint.sh

# 4. Create Custom Entrypoint (INLINE)
RUN printf '#!/bin/bash\n\
    set -Eeuo pipefail\n\
    \n\
    echo "🚀 [ENTRY] Running Official Entrypoint (Setup Only)..."\n\
    # This will now copy files and config but NOT start Apache\n\
    /usr/local/bin/docker-entrypoint.sh apache2-foreground\n\
    \n\
    echo "🔧 [ENTRY] Force-Fixing Apache MPM..."\n\
    a2dismod mpm_event mpm_worker || true\n\
    a2dismod mpm_prefork || true\n\
    a2enmod mpm_prefork\n\
    \n\
    echo "🔎 [ENTRY] Running Custom Init..."\n\
    /usr/local/bin/init-wp.sh\n\
    \n\
    echo "🚀 [ENTRY] Starting Apache..."\n\
    exec "$@"\n\
    ' > /usr/local/bin/custom-entrypoint.sh && chmod +x /usr/local/bin/custom-entrypoint.sh

# 5. Create Init Script (INLINE)
RUN printf '#!/bin/bash\n\
    set -u\n\
    \n\
    # Fallback vars for Railway auto-injection\n\
    DB_HOST="${WORDPRESS_DB_HOST:-${MYSQLHOST:-${MYSQL_HOST:-localhost}}}"\n\
    DB_USER="${WORDPRESS_DB_USER:-${MYSQLUSER:-${MYSQL_USER:-root}}}"\n\
    DB_PASS="${WORDPRESS_DB_PASSWORD:-${MYSQLPASSWORD:-${MYSQL_PASSWORD:-}}}"\n\
    DB_NAME="${WORDPRESS_DB_NAME:-${MYSQLDATABASE:-${MYSQL_DATABASE:-wordpress}}}"\n\
    \n\
    echo "🔎 [INIT] Waiting for DB at $DB_HOST..."\n\
    until mysqladmin ping -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" --silent; do\n\
    echo "   ...db not ready"\n\
    sleep 5\n\
    done\n\
    \n\
    if wp core is-installed --allow-root --path=/var/www/html; then\n\
    echo "✅ [INIT] Already installed"\n\
    else\n\
    echo "⚙️ [INIT] Installing..."\n\
    # Use the detected variables for installation\n\
    wp core install --allow-root --path=/var/www/html --url="${WP_URL:-http://localhost}" --title="${WP_TITLE:-Pixie}" --admin_user="${WP_ADMIN_USER:-admin}" --admin_password="${WP_ADMIN_PASS:-admin123}" --admin_email="${WP_ADMIN_EMAIL:-admin@test.com}" --skip-email\n\
    wp theme install hello-elementor --activate --allow-root --path=/var/www/html\n\
    wp plugin install elementor --activate --allow-root --path=/var/www/html\n\
    fi\n\
    echo "✅ [INIT] Complete"\n\
    ' > /usr/local/bin/init-wp.sh && chmod +x /usr/local/bin/init-wp.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]
