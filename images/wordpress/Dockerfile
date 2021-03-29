FROM wordpress:5.7.0-php7.3-fpm-alpine

ENV WORDPRESS_VERSION 5.7

# Setup
RUN ln -s -f /dev/null /root/.bash_history \
 && rm /usr/local/etc/php-fpm.d/www.conf \
 && cd /tmp && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && mv /tmp/wp-cli.phar /usr/local/bin/wp \
 && chmod 750 /usr/local/bin/wp \
 && chown root:10013 /usr/local/bin/wp

# Permissions
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data

# Required for envsubst variable substitution
RUN apk add gettext

# Configurations
COPY conf/php/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/php/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/php/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/php/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf

# Scripts
RUN mkdir /entrypoint.d
COPY scripts/wordpress/permissions.sh /usr/local/bin
COPY scripts/wordpress/wait-for /usr/local/bin
COPY scripts/wordpress/init.sh /entrypoint.d

RUN chmod 755 /entrypoint.d/init.sh
RUN chmod 755 /usr/local/bin/wait-for
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# Extra extensions
RUN apk add --no-cache icu-dev \
 && docker-php-ext-install intl

# libiconv library for azure single sign-on
# https://github.com/oidc-wp/openid-connect-generic/issues/214
RUN apk add --upgrade gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Upgrade packages
RUN apk update \
 && apk upgrade

COPY entry/wordpress/entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "bash", "entrypoint.sh", "php-fpm"]
