FROM drupal:7.67-fpm-alpine

# User accounts
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data \
 && apk del shadow

# Configurations
COPY conf/php/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/php/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/php/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/php/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY conf/drupal/settings.template /var/www/html/sites/default/settings.template

# Scripts
COPY scripts/drupal/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 * * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# Set permissions
RUN /usr/local/bin/permissions.sh || true

RUN apk add gettext
COPY entry/drupal/entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh"]
