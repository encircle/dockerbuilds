FROM nginx:1.18.0-alpine-perl

# Remove default configs
RUN rm /etc/nginx/nginx.conf
RUN rm /etc/nginx/conf.d/default.conf

# Provide basic auth credentials
RUN printf "USER:MbMfkhm4azvtI" >> /etc/nginx/.htpasswd

# Copy over configurations
COPY conf/nginx/nginx.conf      /etc/nginx/nginx.conf
COPY conf/nginx/default.conf    /etc/nginx/conf.d/default.conf
COPY conf/nginx/cloudflare.conf /etc/nginx/conf.d/cloudflare.conf
COPY conf/nginx/site.key        /etc/nginx/certs/site.key
COPY conf/nginx/site.crt        /etc/nginx/certs/site.crt
COPY conf/nginx/dhparam         /etc/nginx/dhparam

# Run entry script prior to base image
COPY entry/webserver/entrypoint.sh /usr/local/bin
ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh"]
