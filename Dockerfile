FROM wordpress:php8.2-apache

# Instalar WP-CLI sin apt-get (más estable en Railway)
ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

# FIX: evitar "More than one MPM loaded"
RUN a2dismod mpm_event mpm_worker || true \
    && a2enmod mpm_prefork || true

# Scripts de init
COPY init/01-init.sh /docker-entrypoint-initwp.d/01-init.sh
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh

RUN chmod +x /docker-entrypoint-initwp.d/01-init.sh \
    /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]
