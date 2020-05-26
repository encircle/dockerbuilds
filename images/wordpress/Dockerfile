FROM wordpress:php7.3-fpm-alpine
RUN ln -s -f /dev/null /root/.bash_history
RUN rm /usr/local/etc/php-fpm.d/www.conf
RUN cd /tmp && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod 750 /tmp/wp-cli.phar
RUN mv /tmp/wp-cli.phar /usr/local/bin/wp
COPY conf/php/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY entry/wordpress/entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "bash", "entrypoint.sh"]
