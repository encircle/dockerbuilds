FROM php:8.1-fpm-alpine

ENV WORDPRESS_VERSION 6.5.2

# Setup
RUN ln -s -f /dev/null /root/.bash_history \
 && rm /usr/local/etc/php-fpm.d/www.conf \
 && cd /tmp && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && mv /tmp/wp-cli.phar /usr/local/bin/wp \
 && chmod 750 /usr/local/bin/wp \
 && chown root:10013 /usr/local/bin/wp

# wordpress package dependencies
RUN set -eux; \
	apk add --no-cache \
        # PDF previews
        ghostscript \
        imagemagick \
        # PHP SOAP ext
        libxml2-dev \
        icu-dev \
        git \
        nano \
        bash

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		freetype-dev \
		imagemagick-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
	; \
	\
	docker-php-ext-configure gd --with-freetype --with-jpeg; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		mysqli \
		zip \
	; \
    curl 'https://pecl.php.net/get/imagick-3.7.0.tgz' -o imagick-3.4.4.tgz; \
    pecl install -o -f imagick-3.4.4.tgz; \
    docker-php-ext-enable imagick; \
    rm -rf imagick-3.4.4.tgz; \  
    docker-php-ext-install intl bcmath soap; \
	rm -r /tmp/pear; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .wordpress-phpexts-rundeps $runDeps; \
	apk del --no-network .build-deps

# Set recommended PHP opcache settings
RUN set -eux; \
	docker-php-ext-enable opcache; \
	{ \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Other PHP configurations
COPY conf/max_file_upload.ini /usr/local/etc/php/conf.d/max_file_upload.ini
COPY conf/cookie-security.ini /usr/local/etc/php/conf.d/cookie-security.ini
COPY conf/expose_php.ini /usr/local/etc/php/conf.d/expose_php.ini
COPY conf/postfix.ini /usr/local/etc/php/conf.d/postfix.ini
COPY conf/memory_limit.ini /usr/local/etc/php/conf.d/memory_limit.ini
COPY conf/error-logging.ini /usr/local/etc/php/conf.d/error-logging.ini
COPY conf/www.conf /usr/local/etc/php-fpm.d/www.conf

# users and groups
RUN apk add shadow \
 && usermod -u 10013 www-data \
 && groupmod -g 10013 www-data

# Permissions script
COPY wordpress/permissions.sh /usr/local/bin

RUN chmod 755 /usr/local/bin/permissions.sh \
 && crontab -l > /tmp/.cron \
 && echo "0 3 * * * /usr/local/bin/permissions.sh" >> /tmp/.cron \
 && crontab /tmp/.cron \
 && rm -rf /tmp/.cron

# libiconv library for azure single sign-on
# https://github.com/oidc-wp/openid-connect-generic/issues/214
RUN apk add --upgrade gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Upgrade packages
RUN apk update \
 && apk upgrade

COPY wordpress/entrypoint.sh /usr/local/bin/

ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
