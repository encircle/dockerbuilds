FROM php:8.3-fpm-alpine

# ------------------------------------------------------------------------------
# Core system tools
# ------------------------------------------------------------------------------
RUN apk add --no-cache \
    bash \
    nano \
    zip \
    git \
    curl \
    openssh \
    openssh-client \
    mariadb-client \
    nodejs \
    npm \
    linux-headers \
	# Runtime deps for PECL extensions
    libmemcached \
    cyrus-sasl \
    zlib

# ------------------------------------------------------------------------------
# PHP core extensions (gd, pdo, zip, opcache)
# ------------------------------------------------------------------------------
RUN set -eux; \
    apk add --no-cache --virtual .build-php-core \
        $PHPIZE_DEPS \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
        postgresql-dev \
        icu-dev \
        libxml2-dev \
    ; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        gd \
        opcache \
        zip \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        intl \
        bcmath \
        soap \
    ; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-network --virtual .php-rundeps $runDeps; \
    apk del .build-php-core

# ------------------------------------------------------------------------------
# PECL extensions (redis, xdebug, memcached)
# ------------------------------------------------------------------------------
RUN set -eux; \
    apk add --no-cache --virtual .build-pecl \
        $PHPIZE_DEPS \
        libmemcached-dev \
        cyrus-sasl-dev \
        zlib-dev \
        openssl-dev \
        libevent-dev; \
    \
    pecl install redis; \
    pecl install xdebug; \
    pecl install memcached; \
    \
    docker-php-ext-enable redis xdebug memcached; \
    \
    apk del .build-pecl; \
    rm -rf /tmp/pear

# ------------------------------------------------------------------------------
# PHP configuration
# ------------------------------------------------------------------------------
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# additional php configurations
COPY conf/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/memory_limit.ini /usr/local/etc/php/conf.d/memory_limit.ini
COPY conf/memcache.ini /usr/local/etc/php/conf.d/memcache.ini
COPY conf/error-logging.ini /usr/local/etc/php/conf.d/error-logging.ini
COPY conf/drupal.ini /usr/local/etc/php/conf.d/drupal.ini
COPY conf/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf

# ------------------------------------------------------------------------------
# Composer (official binary, no hash required)
# ------------------------------------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# ------------------------------------------------------------------------------
# User / group alignment
# ------------------------------------------------------------------------------
RUN apk add --no-cache --virtual .usermod shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data \
 && usermod --shell /bin/bash www-data \
 && apk del .usermod

# ------------------------------------------------------------------------------
# Drupal directory
# ------------------------------------------------------------------------------
RUN mkdir -p /var/src/drupal \
 && chown -R www-data:www-data /var/src/drupal \
 && chmod -R 755 /var/src

WORKDIR /var/src/drupal/site

# ------------------------------------------------------------------------------
# Drupal / CiviCRM tools
# ------------------------------------------------------------------------------
RUN curl -LsS https://download.civicrm.org/cv/cv.phar -o /usr/local/bin/cv \
 && chmod +x /usr/local/bin/cv

RUN curl -LsS https://download.civicrm.org/civix/civix.phar -o /usr/local/bin/civix \
 && chmod +x /usr/local/bin/civix

RUN ln -sf /var/src/drupal/site/vendor/bin/drush /usr/local/bin/drush || true

# ------------------------------------------------------------------------------
# Node tooling (sass)
# ------------------------------------------------------------------------------
RUN npm install -g sass

# ------------------------------------------------------------------------------
# Permissions cron script (NOTE: cron daemon must be started by entrypoint)
# ------------------------------------------------------------------------------
COPY drupal10/permissions.sh /usr/local/bin/permissions.sh
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l 2>/dev/null | { cat; echo "0 3 * * * /usr/local/bin/permissions.sh"; } | crontab -

# ------------------------------------------------------------------------------
# System upgrade (last)
# ------------------------------------------------------------------------------
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*

# ------------------------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------------------------
COPY drupal10/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

# ------------------------------------------------------------------------------
# PHP-FPM healthcheck
# ------------------------------------------------------------------------------
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD SCRIPT_NAME=/ping \
      SCRIPT_FILENAME=/ping \
      REQUEST_METHOD=GET \
      cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]