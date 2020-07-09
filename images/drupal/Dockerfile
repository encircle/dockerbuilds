FROM drupal:7.67-fpm-alpine

# User accounts
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data \
 && apk del shadow

# Extensions
RUN docker-php-ext-install mysqli

# Configurations
COPY conf/php/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/php/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/php/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/php/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/php/memory_limit.ini /usr/local/etc/php/conf.d/memory_limit.ini
COPY conf/php/memcache.ini /usr/local/etc/php/conf.d/memcache.ini
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Scripts
COPY scripts/drupal/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# Drush
RUN wget https://github.com/drush-ops/drush/releases/download/8.1.17/drush.phar \
 && mv drush.phar /usr/local/bin/drush \
 && chmod 750 /usr/local/bin/drush \
 && apk add mysql-client

ENTRYPOINT ["php-fpm"]
