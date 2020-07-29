FROM encircle/nginx-modsec:latest

RUN mkdir /etc/nginx/client_certs \
 && chmod 755 /etc/nginx/client_certs

# Copy base config
COPY conf/nginx-proxy/nginx.conf  /etc/nginx/nginx.conf
COPY conf/nginx-proxy/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx-proxy/ca.crt /etc/nginx/client_certs/ca.crt

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore nginx
