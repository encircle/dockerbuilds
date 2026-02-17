FROM php:8.3-fpm-alpine

# Disable root shell history
RUN ln -s -f /dev/null /root/.bash_history \
 && rm /usr/local/etc/php-fpm.d/www.conf

# -------------------------------
# Install WP-CLI
# -------------------------------
RUN cd /tmp \
 && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && curl -sS https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar.sha512 \
      | awk '{print $1 "  wp-cli.phar"}' | sha512sum -c - \
 && mv /tmp/wp-cli.phar /usr/local/bin/wp \
 && chmod 750 /usr/local/bin/wp \
 && chown root:10013 /usr/local/bin/wp

# -------------------------------
# Build dependencies
# -------------------------------
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
        icu-dev \
        imagemagick-dev \
        libxml2-dev;

# -------------------------------
# PHP extensions
# -------------------------------
RUN set -eux; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        exif \
        gd \
        mysqli \
        zip \
        intl \
        soap;

# -------------------------------
# Imagick for PHP 8.3
# -------------------------------
RUN apk add --no-cache php83-pecl-imagick

# Install runtime libs required by extensions
RUN set -eux; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-network --virtual .php-rundeps $runDeps; \
    apk del .build-deps;

# -------------------------------
# Install bash, admin tools, and fcgi for healthcheck
# -------------------------------
RUN apk add --no-cache bash git nano fcgi

# -------------------------------
# PDF previews and image processing
# -------------------------------
RUN apk add --no-cache ghostscript imagemagick

# -------------------------------
# Install cv (CiviCRM command line)
# -------------------------------
RUN curl -LsS https://download.civicrm.org/cv/cv.phar -o /usr/local/bin/cv \
 && php /usr/local/bin/cv --version \
 && chmod +x /usr/local/bin/cv

# -------------------------------
# Opcache recommended settings
# -------------------------------
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.save_comments=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# -------------------------------
# Custom PHP configs
# -------------------------------
COPY conf/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/memory_limit.ini /usr/local/etc/php/conf.d/memory_limit.ini
COPY conf/error-logging.ini /usr/local/etc/php/conf.d/error-logging.ini
COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf

# -------------------------------
# Log directory
# -------------------------------
RUN mkdir -p /var/log/php \
 && chown 10013:10013 /var/log/php

# -------------------------------
# User & group adjustments
# -------------------------------
RUN apk add --no-cache --virtual .shadow shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data \
 && apk del .shadow

# -------------------------------
# Permissions script + cron
# -------------------------------
COPY wordpress6/permissions.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron || true \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# -------------------------------
# libiconv fix (Azure SSO issues)
# -------------------------------
RUN apk add --no-cache --upgrade gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# -------------------------------
# Upgrade base OS
# -------------------------------
RUN apk update && apk upgrade && rm -rf /var/cache/apk/*


COPY wordpress6/entrypoint.sh /usr/local/bin/

HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD \
    SCRIPT_NAME=/ping \
    SCRIPT_FILENAME=/ping \
    REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

# -------------------------------
# Entrypoint
# -------------------------------
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]