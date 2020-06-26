FROM php:7.3-fpm-alpine

# Error configuration
RUN { \
                echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
                echo 'display_errors = Off'; \
                echo 'display_startup_errors = Off'; \
                echo 'log_errors = On'; \
                echo 'error_log = /dev/stderr'; \
                echo 'log_errors_max_len = 1024'; \
                echo 'ignore_repeated_errors = On'; \
                echo 'ignore_repeated_source = Off'; \
                echo 'html_errors = Off'; \
        } > /usr/local/etc/php/conf.d/error-logging.ini

# Permissions
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data

# Configurations
COPY conf/php/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/php/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/php/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/php/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Scripts
COPY scripts/wordpress/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# Entrypoint
COPY entry/php7.3/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh"]
