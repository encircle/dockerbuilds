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
    patch \
    openssh \
    openssh-client \
    mariadb-client \
    nodejs \
    npm \
    linux-headers \
	# Runtime deps for PECL extensions
    libmemcached \
    cyrus-sasl \
    zlib \
    fcgi

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
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.save_comments=1'; \
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

RUN chmod 644 /usr/local/etc/php/conf.d/*.ini

# ------------------------------------------------------------------------------
# Log directory
# ------------------------------------------------------------------------------
RUN mkdir -p /var/log/php \
 && chown 10013:10013 /var/log/php

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
# Drupal codebase -- baked in at build time (PED architecture: no runtime
# install, no EFS-mounted codebase). CI runs composer update against the
# previous image's codebase, tarballs the result, and drops it in
# drupal10/src/ (composer project root: web/, vendor/, composer.json/lock)
# before `docker build` runs. See dockerbuilds/ped branch README for the
# full pipeline.
# ------------------------------------------------------------------------------
COPY drupal10/src/ /var/www/html

# No `|| true` here -- the codebase is baked in before this step runs (PED
# architecture), so a missing drush/drush dependency is a real build
# problem, not an expected gap. Fail loudly at build time rather than ship
# an image that only breaks at container boot with "drush: command not found".
RUN ln -sf /var/www/html/vendor/bin/drush /usr/local/bin/drush

WORKDIR /var/www/html

# ------------------------------------------------------------------------------
# RDS CA bundle -- baked in at build time so boot doesn't need internet
# egress for it. RDS enforces require_secure_transport=ON (Invariant #3);
# without this, Drupal's own PDO connection (unlike the raw mariadb CLI
# lock check, which requests --ssl itself) has no way to negotiate TLS,
# and RDS rejects it with a generic "Access denied" that looks exactly
# like a wrong password. generate_settings() in entrypoint.sh references
# this exact path via PDO::MYSQL_ATTR_SSL_CA.
# ------------------------------------------------------------------------------
RUN curl -o /var/www/html/web/sites/default/rds-ca.pem \
    https://truststore.pki.rds.amazonaws.com/eu-west-2/eu-west-2-bundle.pem \
 && chown root:10013 /var/www/html/web/sites/default/rds-ca.pem \
 && chmod 640 /var/www/html/web/sites/default/rds-ca.pem

# ------------------------------------------------------------------------------
# Node tooling (sass)
# ------------------------------------------------------------------------------
RUN npm install -g sass

# ------------------------------------------------------------------------------
# Permissions -- hardened once at build time, against the image's own layer.
# Public files (sites/default/files) and private files (private/) are EFS
# mount points at runtime; their ownership comes from the EFS access
# point's configured POSIX identity (uid/gid 33, i.e. www-data) instead, so
# only empty mount-point directories are needed here.
# ------------------------------------------------------------------------------
RUN chown root:10013 /var/www/html/web \
 && chmod 750 /var/www/html/web \
 && find /var/www/html/web -maxdepth 1 -type f -exec chown root:10013 {} + \
 && find /var/www/html/web -maxdepth 1 -type f ! -perm 0740 -exec chmod 740 {} + \
 && find /var/www/html/web -exec chown root:10013 {} + \
 && find /var/www/html/web -type d ! -perm 0750 -exec chmod 750 {} + \
 && find /var/www/html/web -type f ! -perm 0640 -exec chmod 640 {} + \
 && mkdir -p /var/www/html/web/sites/default/files /var/www/html/private \
 && chown 10013:10013 /var/www/html/web/sites/default/files /var/www/html/private

# Config-sync YAML (ped-drupal's config/sync, dropped in alongside the
# codebase by CI -- outside the docroot, never web-served, read-only at
# runtime since drush only ever reads it to import into the DB).
RUN mkdir -p /var/www/html/config/sync \
 && chown -R root:10013 /var/www/html/config \
 && find /var/www/html/config -type d -exec chmod 750 {} + \
 && find /var/www/html/config -type f -exec chmod 640 {} +

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
HEALTHCHECK --interval=30s --timeout=5s --retries=3 --start-period=120s \
  CMD SCRIPT_NAME=/ping \
      SCRIPT_FILENAME=/ping \
      REQUEST_METHOD=GET \
      cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]