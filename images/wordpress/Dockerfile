FROM wordpress:5.4.1-php7.3-fpm-alpine

# Setup
RUN ln -s -f /dev/null /root/.bash_history \
 && rm /usr/local/etc/php-fpm.d/www.conf \
 && cd /tmp && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod 750 /tmp/wp-cli.phar \
 && mv /tmp/wp-cli.phar /usr/local/bin/wp

# Permissions
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data

# Configurations
COPY conf/php/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/php/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Scripts
COPY scripts/wordpress/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 * * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

COPY entry/wordpress/entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "bash", "entrypoint.sh"]
