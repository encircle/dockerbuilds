FROM php:8.1-fpm-alpine

ENV COMPOSER_SHA384 dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6
ENV DRUPAL_VERSION 10.2.10
ENV CIVICRM_VERSION 5.78.2

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
		openssh \
	; \
	\
	docker-php-ext-configure gd --with-freetype --with-jpeg\
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

RUN set -eux;\
# build tools
apk add --no-cache --virtual .build-deps autoconf g++ make; \
apk add --update linux-headers; \
apk add openssh-client; \

# redis
 curl 'https://pecl.php.net/get/redis-5.3.7.tgz' -o redis-5.3.7.tgz; \
 pecl install -o -f redis-5.3.7.tgz; \
 docker-php-ext-enable redis; \
 rm -rf redis-5.3.7.tgz; \
# xdebug
 curl 'https://pecl.php.net/get/xdebug-3.2.0.tgz' -o xdebug-3.2.0.tgz;\
 pecl install -o -f xdebug-3.2.0.tgz; \
 docker-php-ext-enable xdebug; \
 rm -rf xdebug-3.2.0.tgz; \
# memcache
apk add --no-cache \
        libpq \
        libmemcached-dev \
        zlib-dev \
        curl;\
curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/v3.2.0.tar.gz";\
mkdir -p /usr/src/php/ext/memcached;\
tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1;\
docker-php-ext-configure memcached;\
docker-php-ext-install memcached;\
rm /tmp/memcached.tar.gz;\
# mysqli
docker-php-ext-install mysqli && docker-php-ext-enable mysqli ;\
# intl, bcmap, soap
apk add --no-cache\
        icu-dev\
        libxml2-dev;\
docker-php-ext-install intl bcmath soap;\
# patch
apk add --no-cache patch;\
# remove cache
apk del --no-network .build-deps;\
# clear cache
rm -rf /tmp/pear

# set recommended opcache settings
# see https://secure.php.net/manual/en/opcache.installation.php
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
COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf

# composer
RUN set -eux;\
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');";\
  php -r "if (hash_file('sha384', 'composer-setup.php') === '${COMPOSER_SHA384}') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); };" \
  && php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet;\
  rm composer-setup.php

# user accounts
RUN apk add --no-cache --virtual .build-deps shadow;\
            usermod -u 10013 www-data;\
            groupmod -g 10013 www-data;\
            usemod --shell /bin/bash;\
            apk del shadow

# directory for composer drupal project
RUN mkdir -p /var/src/drupal \
 && chmod -R 755 /var/src

# scripts
COPY drupal9/permissions.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# mysql package for drush
RUN apk add --no-cache mariadb-client

RUN ln -s /var/src/drupal/site/vendor/bin/drush /usr/local/bin/drush || true

RUN curl -LsS https://download.civicrm.org/cv/cv.phar -o /usr/local/bin/cv
RUN chmod +x /usr/local/bin/cv

#install civix
RUN curl -LsS https://download.civicrm.org/civix/civix.phar -o /usr/local/bin/civix \
 && chmod +x /usr/local/bin/civix

# admin packages
RUN apk add --no-cache git nano bash zip

#sass
RUN apk add --no-cache nodejs npm && npm install -g sass

# upgrade packages
RUN apk update \
 && apk upgrade

# entrypoint
COPY drupal10/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

WORKDIR /var/src/drupal/site
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
