FROM wordpress:php7.3-fpm-alpine
RUN ln -s -f /dev/null /root/.bash_history
RUN rm /usr/local/etc/php-fpm.d/www.conf
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf
RUN find /var/www -exec chown 101:www-data {} \;
RUN find /var/www -type f -exec chmod 640 {} \;
RUN find /var/www -type d -exec chmod 750 {} \;
RUN find /var/www -wholename *wp-content/uploads* -type d -exec chmod 770 {} \;
RUN find /var/www -wholename *wp-content/uploads* -type f -exec chmod 660 {} \;
RUN find /var/www -wholename *wp-content/plugins* -type d -exec chmod 770 {} \;
RUN find /var/www -wholename *wp-content/plugins* -type f -exec chmod 660 {} \;
