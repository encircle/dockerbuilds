FROM encircle/nginx-modsec:latest

# Copy base config
COPY default.conf /etc/nginx/conf.d/default.conf

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore nginx

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
    CMD curl -so /dev/null -w '%{http_code}' http://localhost/ | grep -q 301 || exit 1
