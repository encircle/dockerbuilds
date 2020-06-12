ARG NGINX_VERSION=1.19.0
ARG MODSEC_VERSION=3
ARG OWASP_CRS_VERSION=3.0.2

# Temporary image for compilations
FROM nginx:${NGINX_VERSION}-alpine-perl as build

ARG NGINX_VERSION
ARG MODSEC_VERSION

ENV ENV_MODSEC_VERSION=${MODSEC_VERSION}
ENV ENV_NGINX_VERSION=${NGINX_VERSION}

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

# ClamAV
COPY scripts/clamav/clamav-hook.pl /usr/local/bin/clamav-hook.pl
RUN chmod 750 /usr/local/bin/clamav-hook.pl
RUN apk add clamav clamav-libunrar
RUN mkdir /run/clamav
RUN chown clamav:clamav /run/clamav
RUN chmod 750 /run/clamav
RUN freshclam

# NGINX configurations
RUN rm /etc/nginx/nginx.conf \
 && rm /etc/nginx/conf.d/default.conf \
 && printf "USER:MbMfkhm4azvtI" >> /etc/nginx/.htpasswd

COPY conf/nginx/nginx-modsec.conf  /etc/nginx/nginx.conf
COPY conf/nginx/default.conf       /etc/nginx/conf.d/default.conf
COPY conf/nginx/cloudflare.conf    /etc/nginx/conf.d/cloudflare.conf
COPY conf/nginx/certs/site.key           /etc/nginx/certs/site.key
COPY conf/nginx/certs/site.crt           /etc/nginx/certs/site.crt
COPY conf/nginx/dhparam            /etc/nginx/dhparam
COPY conf/nginx/error.html         /var/www/error.html

# Modsecurity configurations
RUN apk add pcre-dev \
    zlib-dev \
    openssl-dev \
    libmaxminddb \
    yajl-dev \
 && mkdir /etc/nginx/modsec

COPY conf/modsecurity/modsecurity-clamav.conf /etc/nginx/modsec/modsecurity.conf
COPY conf/modsecurity/unicode.mapping  /etc/nginx/modsec/unicode.mapping
COPY conf/nginx/modsecurity.conf       /etc/nginx/conf.d/modsecurity.conf

RUN cd /tmp \
 && wget https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v${OWASP_CRS_VERSION}.tar.gz \
 && tar -xvzf /tmp/v${ENV_OWASP_CRS_VERSION}.tar.gz -C /etc/nginx/modsec \
 && mv /etc/nginx/modsec/owasp-modsecurity-crs-${ENV_OWASP_CRS_VERSION}/crs-setup.conf.example /etc/nginx/modsec/owasp-modsecurity-crs-${ENV_OWASP_CRS_VERSION}/crs-setup.conf \
 && rm -rf /tmp/owasp-modsecurity-crs-${ENV_OWASP_CRS_VERSION}.tar.gz

# Entrypoint
COPY entry/nginx-modsec-clamav/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh
CMD /usr/local/bin/entrypoint.sh
