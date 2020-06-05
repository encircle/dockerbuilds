FROM nginx:1.19.0-alpine-perl

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
<<<<<<< HEAD
=======
COPY conf/nginx/error.html      /var/www/error.html
>>>>>>> v1.0.5

# Run entry script prior to base image
COPY entry/webserver/entrypoint.sh /usr/local/bin
RUN chmod 755 /usr/local/bin/entrypoint.sh
CMD /usr/local/bin/entrypoint.sh
