FROM wordpress:php8.2-apache

# Dependencias mínimas (sin mysql-client)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# WP-CLI
RUN curl -L -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Init scripts
COPY init/01-init.sh /docker-entrypoint-initwp.d/01-init.sh
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh

RUN chmod +x /docker-entrypoint-initwp.d/01-init.sh /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]
