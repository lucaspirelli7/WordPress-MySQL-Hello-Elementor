# Base WordPress
FROM wordpress:php8.2-apache

# Traemos wp-cli desde la imagen oficial (sin apt, sin curl)
FROM wpcli/wp-cli:php8.2 AS wpcli

FROM wordpress:php8.2-apache

# Copiamos wp-cli
COPY --from=wpcli /usr/local/bin/wp /usr/local/bin/wp

# Copiamos scripts
COPY init/01-init.sh /usr/local/bin/run-init-tasks.sh
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh

RUN chmod +x /usr/local/bin/run-init-tasks.sh /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]
