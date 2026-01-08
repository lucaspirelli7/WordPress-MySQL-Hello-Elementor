FROM wordpress:php8.2-apache

# Install dependencies required for the init script (mysql-client for ping, wp-cli)
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    less \
    && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy init script and entrypoint
COPY init/01-init.sh /usr/local/bin/run-init-tasks.sh
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh

# Make them executable
RUN chmod +x /usr/local/bin/run-init-tasks.sh /usr/local/bin/custom-entrypoint.sh

# Set the custom entrypoint
ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]