FROM encircle/nginx-modsec:latest

# Copy base config
COPY default.conf /etc/nginx/conf.d/default.conf

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore nginx
