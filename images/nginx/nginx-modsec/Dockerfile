ARG NGINX_VERSION=1.29.3
ARG MODSEC_VERSION=3
ARG OWASP_CRS_VERSION=4.3.0

#
# ===============================
# Build stage – compile ModSecurity
# ===============================
#
FROM nginx:${NGINX_VERSION}-alpine-perl AS build

ARG NGINX_VERSION
ARG MODSEC_VERSION

ENV ENV_MODSEC_VERSION=${MODSEC_VERSION}
ENV ENV_NGINX_VERSION=${NGINX_VERSION}
ENV WEBROOT=/var/www/html/web

# Dependencies for building ModSecurity + connector
RUN apk add --no-cache --virtual build-deps \
    gcc g++ make libc-dev openssl-dev linux-headers \
    pcre2-dev zlib-dev git libtool automake autoconf \
    lmdb-dev libxml2-dev curl-dev byacc flex wget \
    yajl-dev libstdc++ libmaxminddb-dev

#
# 1. Build ModSecurity v3
#
RUN cd /tmp \
 && git clone --depth 1 -b v${ENV_MODSEC_VERSION}/master --single-branch \
        https://github.com/SpiderLabs/ModSecurity \
 && cd ModSecurity \
 && git submodule update --init --recursive --depth 1 \
 && ./build.sh \
 && ./configure \
 && make -j"$(nproc)" \
 && make install

#
# 2. Build nginx connector
#
# Compile Modsecurity NGINX connector
RUN cd /tmp \
 && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
 && wget https://nginx.org/download/nginx-${ENV_NGINX_VERSION}.tar.gz \
 && tar -xzf nginx-${ENV_NGINX_VERSION}.tar.gz \
 && cd /tmp/nginx-${ENV_NGINX_VERSION} \
 && ./configure \
      --with-compat \
      --with-pcre-jit \
      --add-dynamic-module=/tmp/ModSecurity-nginx \
      --with-cc-opt="-I/usr/include" \
      --with-ld-opt="-L/usr/lib" \
 && make modules -j"$(nproc)"

#
# ===============================
# Final runtime image
# ===============================
#
FROM nginx:${NGINX_VERSION}-alpine-perl

ARG OWASP_CRS_VERSION
ENV ENV_OWASP_CRS_VERSION=${OWASP_CRS_VERSION}
ENV WEBROOT=/var/www/html/web

# Runtime dependencies
RUN apk add --no-cache \
    yajl \
    libstdc++ \
    libmaxminddb \
    lmdb \
    libxml2 \
    curl \
    pcre2

# Copy ModSecurity binaries
COPY --from=build /tmp/nginx-${NGINX_VERSION}/objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/
COPY --from=build /usr/local/modsecurity/ /usr/local/modsecurity/

# Users & groups
RUN apk add --no-cache --virtual .shadow shadow \
 && usermod -u 10014 nginx \
 && groupmod -g 10014 nginx \
 && groupmod -g 10013 www-data \
 && usermod -aG www-data nginx \
 && apk del .shadow

#
# ===============================
# Drupal codebase -- baked in at build time (PED architecture). nginx
# serves static assets (css/js/images) directly from $WEBROOT via
# try_files before falling back to PHP-FPM, so it needs the same docroot
# php-fpm has, not just a reverse-proxy config. The CI/build pipeline
# drops the composer-built codebase in src/ (same artifact used for the
# php-fpm image) before `docker build` runs; only web/ is copied in here.
# ===============================
#
COPY src/web/ /var/www/html/web

# Numeric GID (10013), not the symbolic "www-data" name -- the group name
# doesn't reliably resolve at this point in this base image, even after
# the "Users & groups" groupmod above. Same numeric convention already
# used by this Dockerfile's own log directories and by drupal10's.
RUN chown root:10013 /var/www/html/web \
 && chmod 750 /var/www/html/web \
 && find /var/www/html/web -maxdepth 1 -type f -exec chown root:10013 {} + \
 && find /var/www/html/web -maxdepth 1 -type f ! -perm 0740 -exec chmod 740 {} + \
 && find /var/www/html/web -exec chown root:10013 {} + \
 && find /var/www/html/web -type d ! -perm 0750 -exec chmod 750 {} + \
 && find /var/www/html/web -type f ! -perm 0640 -exec chmod 640 {} + \
 && mkdir -p /var/www/html/web/sites/default/files \
 && chown 10013:10013 /var/www/html/web/sites/default/files

#
# ===============================
# NGINX configs
# ===============================
#
RUN rm /etc/nginx/nginx.conf \
 && rm /etc/nginx/conf.d/default.conf \
 && printf "USER:MbMfkhm4azvtI" >> /etc/nginx/.htpasswd

COPY nginx.conf        /etc/nginx/nginx.conf
COPY default.conf      /etc/nginx/conf.d/default.conf
COPY fastcgi.conf      /etc/nginx/conf.d/fastcgi.conf

COPY hardening/*.conf  /etc/nginx/hardening.d/
COPY hardening/error.html /var/www/error.html
RUN chown root:www-data /var/www/error.html \
 && chmod 640 /var/www/error.html

# site.crt/site.key (the real origin TLS cert/key) are deliberately NOT
# copied in here -- they used to be, baked in from a committed dev
# placeholder that was self-signed and sat expired in git for years
# (PED OAT reconciliation, 2026-07). A private key must never live in a
# git-committed image layer. The PED deployment now fetches the real
# cert/key from Secrets Manager at instance boot and bind-mounts them into
# /etc/nginx/certs/site.{crt,key} (see ho-ped/templates/userdata-dmz.sh.tpl
# and docker-compose/dmz/docker-compose.yml) -- this image will not start
# nginx successfully without that mount (or an equivalent one) present.
COPY certs/444.key      /etc/nginx/certs/444.key
COPY certs/444.crt      /etc/nginx/certs/444.crt
COPY certs/client.crt   /etc/nginx/certs/client.crt
COPY certs/client.key   /etc/nginx/certs/client.key
COPY dhparam            /etc/nginx/dhparam
RUN chown root:nginx /etc/nginx/certs/*.key /etc/nginx/dhparam \
 && chmod 640 /etc/nginx/certs/*.key /etc/nginx/dhparam \
 && chmod 644 /etc/nginx/certs/*.crt

#
# ===============================
# ModSecurity config
# ===============================
#
RUN mkdir -p /etc/nginx/modsec

COPY modsecurity.conf       /etc/nginx/modsec/modsecurity.conf
COPY unicode.mapping        /etc/nginx/modsec/unicode.mapping
COPY nginx-modsecurity.conf /etc/nginx/conf.d/modsecurity.conf

RUN mkdir /tmp/modsec \
 && chown nginx:nginx /tmp/modsec \
 && chmod 700 /tmp/modsec \
 && mkdir -p /var/log/nginx/modsec_audit \
 && chown nginx:nginx /var/log/nginx/modsec_audit \
 && chmod 700 /var/log/nginx/modsec_audit \
 && mkdir -p /var/cache/nginx/microcache \
 && chown nginx:nginx /var/cache/nginx/microcache \
 && chmod 700 /var/cache/nginx/microcache

# Admin tools
RUN apk add jq bash

#
# ===============================
# OWASP CRS (latest 4.3.0)
# ===============================
#
RUN cd /tmp \
 && wget https://github.com/coreruleset/coreruleset/archive/refs/tags/v${ENV_OWASP_CRS_VERSION}.tar.gz \
 && tar -xzf v${ENV_OWASP_CRS_VERSION}.tar.gz -C /etc/nginx/modsec \
 && test -d /etc/nginx/modsec/coreruleset-${ENV_OWASP_CRS_VERSION}/rules \
 && mv /etc/nginx/modsec/coreruleset-${ENV_OWASP_CRS_VERSION}/crs-setup.conf.example \
       /etc/nginx/modsec/coreruleset-${ENV_OWASP_CRS_VERSION}/crs-setup.conf \
 && mkdir -p /etc/nginx/modsec/whitelist \
 && touch /etc/nginx/modsec/whitelist/whitelist.conf

# Custom rule exclusions and crs-setup overrides
COPY REQUEST-900-EXCLUSIONS.conf /etc/nginx/modsec/REQUEST-900-EXCLUSIONS.conf
COPY RESPONSE-999-EXCLUSIONS-AFTER-CRS.conf /etc/nginx/modsec/RESPONSE-999-EXCLUSIONS-AFTER-CRS.conf
COPY crs-setup.conf /etc/nginx/modsec/coreruleset-${ENV_OWASP_CRS_VERSION}/crs-setup.conf

#
# ===============================
# Upgrade OS packages
# ===============================
#
RUN apk update && apk upgrade --ignore nginx

RUN rm -rf /tmp/*

#
# Entrypoint
# ===============================
#
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -so /dev/null -w '%{http_code}' http://localhost/ | grep -q 301 || exit 1

CMD /usr/local/bin/entrypoint.sh
