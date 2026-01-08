FROM wordpress:php8.2-apache

ADD https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar /usr/local/bin/wp
RUN chmod +x /usr/local/bin/wp

COPY init/01-init.sh /docker-entrypoint-initwp.d/01-init.sh
COPY entrypoint.sh /usr/local/bin/custom-entrypoint.sh
RUN chmod +x /docker-entrypoint-initwp.d/01-init.sh /usr/local/bin/custom-entrypoint.sh

RUN a2dismod mpm_event mpm_worker || true && a2enmod mpm_prefork || true

ENTRYPOINT ["custom-entrypoint.sh"]
CMD ["apache2-foreground"]