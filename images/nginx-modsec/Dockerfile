FROM nginx:1.18.0-alpine-perl

# Remove default configs
RUN rm /etc/nginx/nginx.conf
RUN rm /etc/nginx/conf.d/default.conf

# Provide basic auth credentials
RUN printf "USER:MbMfkhm4azvtI" >> /etc/nginx/.htpasswd

# Copy over configurations
COPY conf/nginx/nginx-modsec.conf      /etc/nginx/nginx.conf
COPY conf/nginx/default.conf    /etc/nginx/conf.d/default.conf
COPY conf/nginx/cloudflare.conf /etc/nginx/conf.d/cloudflare.conf
COPY conf/nginx/site.key        /etc/nginx/certs/site.key
COPY conf/nginx/site.crt        /etc/nginx/certs/site.crt
COPY conf/nginx/dhparam         /etc/nginx/dhparam

# Modsecurity
RUN apk add pcre-dev zlib-dev openssl-dev libmaxminddb yajl-dev
RUN mkdir /etc/nginx/modsec

COPY software/modsecurity-precompiled.tar.gz /tmp/modsecurity-precompiled.tar.gz
COPY software/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/ngx_http_modsecurity_module.so
COPY software/owasp-modsecurity-crs-3.0.2.tar.gz /tmp/owasp-modsecurity-crs-3.0.2.tar.gz

COPY conf/modsecurity/modsecurity.conf /etc/nginx/modsec/modsecurity.conf
COPY conf/modsecurity/unicode.mapping /etc/nginx/modsec/unicode.mapping
COPY conf/nginx/modsecurity.conf /etc/nginx/conf.d/modsecurity.conf

RUN tar -xvzf /tmp/modsecurity-precompiled.tar.gz -C /usr/local
RUN tar -xvzf /tmp/owasp-modsecurity-crs-3.0.2.tar.gz -C /etc/nginx/modsec
RUN mv /etc/nginx/modsec/owasp-modsecurity-crs-3.0.2/crs-setup.conf.example /etc/nginx/modsec/owasp-modsecurity-crs-3.0.2/crs-setup.conf

RUN rm -rf /tmp/modsecurity-precompiled.tar.gz
RUN rm -rf /tmp/owasp-modsecurity-crs-3.0.2.tar.gz

# Run entry script prior to base image
COPY entry/webserver/entrypoint-modsec.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh
CMD /usr/local/bin/entrypoint.sh
