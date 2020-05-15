FROM wordpress:php7.3-fpm-alpine
RUN ln -s -f /dev/null /root/.bash_history
RUN rm /usr/local/etc/php-fpm.d/www.conf
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf
