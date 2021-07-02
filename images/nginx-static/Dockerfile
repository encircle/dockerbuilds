FROM encircle/nginx-modsec:latest

# Copy base config
COPY conf/nginx-static/default.conf /etc/nginx/conf.d/default.conf

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore nginx
