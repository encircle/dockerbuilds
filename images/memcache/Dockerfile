FROM alpine:3.7

RUN apk update && apk upgrade
RUN apk add --no-cache php7-pear php7-dev gcc musl-dev make
RUN pecl install xdebug
RUN apk add --no-cache --update libmemcached-libs zlib

RUN set -xe && \
    cd /tmp/ && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update --virtual .memcached-deps zlib-dev libmemcached-dev cyrus-sasl-dev && \

    pecl install igbinary && \

    ( \
        pecl install --nobuild memcached && \
        cd "$(pecl config-get temp_dir)/memcached" && \
        phpize && \
        ./configure --enable-memcached-igbinary && \
        make -j$(nproc) && \
        make install && \
        cd /tmp/ \
    ) && \

    docker-php-ext-enable igbinary memcached && \
    rm -rf /tmp/* && \
    apk del .memcached-deps .phpize-deps

ENTRYPOINT ["/usr/bin/memcached \
  --user=${MEMCACHED_USER:-memcached} \
  --listen=${MEMCACHED_HOST:-0.0.0.0} \
  --port=${MEMCACHED_PORT:-11211} \
  --memory-limit=${MEMCACHED_MEMUSAGE:-64} \
  --conn-limit=${MEMCACHED_MAXCONN:-1024} \
  --threads=${MEMCACHED_THREADS:-4} \
  --max-reqs-per-event=${MEMCACHED_REQUESTS_PER_EVENT:-20} \
  --verbose"]
