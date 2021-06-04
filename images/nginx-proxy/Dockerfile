FROM encircle/nginx-modsec:latest

RUN mkdir /etc/nginx/client_certs \
 && chmod 755 /etc/nginx/client_certs

# Copy base config
COPY conf/nginx-proxy/default.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx-proxy/ca.crt /etc/nginx/client_certs/ca.crt

# increase client_max_body_size
RUN sed -i -E "s/client_max_body_size.+/client_max_body_size 1024m;/g" /etc/nginx/nginx.conf

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore nginx
