FROM php:7.3-fpm-alpine

ENV COMPOSER_MD5 091fbf803063d9e6a05270282f887c10
ENV DRUPAL_VERSION 9.2.4
ENV DRUPAL_MD5 e71724d790495869b8d4bba1a917804e
ENV DRUSH_VERSION 8.3.5

# install the PHP extensions we need
RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		freetype-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
# postgresql-dev is needed for https://bugs.alpinelinux.org/issues/3642
		postgresql-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype-dir \
		--with-jpeg-dir=/usr/include \
	; \
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
	apk add --no-network --virtual .drupal-phpexts-rundeps $runDeps; \
	apk del --no-network .build-deps

# PHP redis
RUN apk add autoconf g++ make \
 && pecl install -o -f redis \
 && rm -rf /tmp/pear \
 && docker-php-ext-enable redis \
 && apk del autoconf g++

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Install composer
RUN set -eux; \
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"; \
  echo "${COMPOSER_MD5} *composer-setup.php" | md5sum -c -; \
  php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet \
    && rm composer-setup.php;

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

RUN curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/v3.1.5.tar.gz" \
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

# Directory for composer drupal project
RUN mkdir -p /var/src/drupal \
 && chmod -R 755 /var/src

# Scripts
COPY drupal9/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# Extra PHP extensions
RUN apk add --no-cache icu-dev \
                       libxml2-dev \
 && docker-php-ext-install intl bcmath soap

# mysql package for drush
RUN apk add --no-cache mariadb-client

# admin packages
RUN apk add --no-cache git nano bash

# Upgrade packages
RUN apk update \
 && apk upgrade

# Entrypoint
COPY drupal9/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

WORKDIR /var/src/drupal/site
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
