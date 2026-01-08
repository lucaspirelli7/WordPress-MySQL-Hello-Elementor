FROM wordpress:php8.2-apache

# Install minimal dependencies for wp-cli and mysql check
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    less \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy scripts
COPY init/01-init.sh /usr/local/bin/init-wp.sh
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh

# Make executable
RUN chmod +x /usr/local/bin/init-wp.sh /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]
