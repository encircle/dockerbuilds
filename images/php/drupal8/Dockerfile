FROM php:7.4-fpm-alpine

ENV DRUPAL_VERSION 8.9.20
ENV DRUPAL_MD5 03c77251b7332bf7e194b9702b077dd2
ENV COMPOSER_MD5 a0eab6b2bdd35a9605ecc79a71618f46
ENV DRUSH_VERSION 8.3.5

# install the PHP extensions we need
# postgresql-dev is needed for https://bugs.alpinelinux.org/issues/3642
RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		freetype-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
		postgresql-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype --with-jpeg; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .drupal-phpexts-rundeps $runDeps; \
	apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Get Drupal source
RUN set -eux; \
    curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz; \
    echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
    tar -xz --strip-components=1 -f drupal.tar.gz; \
    rm drupal.tar.gz; \
    chown -R www-data:www-data sites modules themes

# Install composer
RUN set -eux; \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
    echo "${COMPOSER_MD5} *composer-setup.php" | md5sum -c -; \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet \
      && rm composer-setup.php; \
    composer install

# Add composer binaries to path
ENV PATH="/var/www/vendor/bin:${PATH}"

# Drush extensions
RUN docker-php-ext-install mysqli

# User accounts
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data \
 && apk del shadow

## Memcache ##
RUN apk update && apk add \
    libpq \
    libmemcached-dev \
    zlib-dev \
    curl

RUN curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/v3.3.0.tar.gz" \
    && mkdir -p /usr/src/php/ext/memcached \
    && tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached \
    && rm /tmp/memcached.tar.gz
## Memcache ##

# PHP Configurations
COPY conf/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/memory_limit.ini /usr/local/etc/php/conf.d/memory_limit.ini
COPY conf/memcache.ini /usr/local/etc/php/conf.d/memcache.ini
COPY conf/error-logging.ini /usr/local/etc/php/conf.d/error-logging.ini
COPY conf/drupal.ini /usr/local/etc/php/conf.d/drupal.ini
COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf

# Scripts
COPY drupal8/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# Drush
RUN wget https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar \
 && docker-php-ext-install mysqli \
 && mv drush.phar /usr/local/bin/drush \
 && chmod 750 /usr/local/bin/drush \
 && chown root:10013 /usr/local/bin/drush \
 && apk add mysql-client

# Extra extensions
RUN apk add --no-cache \
            icu-dev \
            libxml2-dev \
 && docker-php-ext-install intl bcmath soap

# admin packages
RUN apk add --no-cache git nano bash

# Upgrade packages
RUN apk update \
 && apk upgrade

# Entrypoint
COPY drupal8/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
