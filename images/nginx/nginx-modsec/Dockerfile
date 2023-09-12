ARG NGINX_VERSION=1.19.0
ARG MODSEC_VERSION=3
ARG OWASP_CRS_VERSION=3.3.0

# Temporary image for Modsecurity compilations
FROM nginx:${NGINX_VERSION}-alpine-perl as build

ARG NGINX_VERSION
ARG MODSEC_VERSION

ENV ENV_MODSEC_VERSION=${MODSEC_VERSION}
ENV ENV_NGINX_VERSION=${NGINX_VERSION}
ENV WEBROOT /var/www/html

# Dependencies
RUN apk add --no-cache --virtual general-dependencies \
    gcc \
    make \
    libc-dev \
    g++ \
    openssl-dev \
    linux-headers \
    pcre-dev \
    zlib-dev \
    git \
    libtool \
    automake \
    autoconf \
    lmdb-dev \
    libxml2-dev \
    curl-dev \
    byacc \
    flex \
    wget \
    yajl-dev \
    libstdc++ \
    libmaxminddb-dev

# Compile Modsecurity
RUN cd /tmp \
 && git clone --depth 1 -b v${ENV_MODSEC_VERSION}/master --single-branch https://github.com/SpiderLabs/ModSecurity \
 && cd ModSecurity \
 && git submodule init \
 && git submodule update \
 && ./build.sh \
 && ./configure \
 && make \
 && make install

# Compile Modsecurity NGINX connector
RUN cd /tmp \
 && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
 && wget http://nginx.org/download/nginx-${ENV_NGINX_VERSION}.tar.gz \
 && tar -xvzf nginx-${ENV_NGINX_VERSION}.tar.gz \
 && cd /tmp/nginx-${ENV_NGINX_VERSION} \
 && ./configure --with-compat --add-dynamic-module=/tmp/ModSecurity-nginx \
 && make modules

# The actual image
FROM nginx:${NGINX_VERSION}-alpine-perl

ARG OWASP_CRS_VERSION
ENV ENV_OWASP_CRS_VERSION=${OWASP_CRS_VERSION}
ENV WEBROOT /var/www/html

# Dependencies
RUN apk add --no-cache \
    yajl \
    libstdc++ \
    libmaxminddb-dev \
    lmdb-dev \
    libxml2-dev \
    curl-dev

# Copy over precompiled binaries
COPY --from=build /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/local/modsecurity/ /usr/local/modsecurity/

# Users and groups
RUN apk add shadow \
 && usermod -u 10014 nginx \
 && groupmod -g 10014 nginx \
 && groupmod -g 10013 www-data \
 && usermod -aG www-data nginx \
 && apk del shadow

# NGINX configurations
RUN rm /etc/nginx/nginx.conf \
 && rm /etc/nginx/conf.d/default.conf \
 && printf "USER:MbMfkhm4azvtI" >> /etc/nginx/.htpasswd

# Copy base config
COPY nginx.conf  /etc/nginx/nginx.conf
COPY default.conf       /etc/nginx/conf.d/default.conf
COPY fastcgi_buffer_size.conf /etc/nginx/conf.d/fastcgi_buffer_size.conf

# Copy hardening configs
COPY hardening/*.conf /etc/nginx/hardening.d/
COPY hardening/error.html /var/www/error.html
RUN chown root:www-data /var/www/error.html \
 && chmod 640 /var/www/error.html

# Copy SSL
COPY certs/site.key     /etc/nginx/certs/site.key
COPY certs/site.crt     /etc/nginx/certs/site.crt
COPY certs/444.key      /etc/nginx/certs/444.key
COPY certs/444.crt      /etc/nginx/certs/444.crt
COPY certs/client.crt   /etc/nginx/certs/client.crt
COPY certs/client.key   /etc/nginx/certs/client.key
COPY dhparam            /etc/nginx/dhparam

# Modsecurity configurations
RUN apk add pcre-dev \
    zlib-dev \
    openssl-dev \
    libmaxminddb \
    yajl-dev \
 && mkdir /etc/nginx/modsec

COPY modsecurity.conf       /etc/nginx/modsec/modsecurity.conf
COPY unicode.mapping        /etc/nginx/modsec/unicode.mapping
COPY nginx-modsecurity.conf /etc/nginx/conf.d/modsecurity.conf
COPY clamd-hook.sh          /usr/local/bin/clamd-hook.sh

# ClamAV configurations
RUN chown root:nginx /usr/local/bin/clamd-hook.sh \
 && chmod 750 /usr/local/bin/clamd-hook.sh \
 && mkdir /tmp/modsec \
 && chown nginx:nginx /tmp/modsec \
 && chmod 700 /tmp/modsec

# add admin user packages 
RUN apk add jq \
 && apk add bash

# OWASP ruleset
RUN cd /tmp \
 && wget https://github.com/coreruleset/coreruleset/archive/v${OWASP_CRS_VERSION}.tar.gz \
 && tar -xvzf /tmp/v${ENV_OWASP_CRS_VERSION}.tar.gz -C /etc/nginx/modsec \
 && mv /etc/nginx/modsec/coreruleset-${ENV_OWASP_CRS_VERSION}/crs-setup.conf.example /etc/nginx/modsec/coreruleset-${ENV_OWASP_CRS_VERSION}/crs-setup.conf \
 && rm -rf /tmp/coreruleset-${ENV_OWASP_CRS_VERSION}.tar.gz \
 && mkdir /etc/nginx/modsec/whitelist \
 && touch /etc/nginx/modsec/whitelist/whitelist.conf

# CRS set up
COPY crs-setup.conf   /etc/nginx/modsec/coreruleset-${OWASP_CRS_VERSION}/crs-setup.conf

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore nginx

# Entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh
CMD /usr/local/bin/entrypoint.sh
