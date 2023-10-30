
FROM debian:bullseye
RUN mkdir -p /var/www/html

RUN usermod -u 10013 www-data \
&& groupmod -g 10013 www-data 


RUN apt update
RUN apt install software-properties-common ca-certificates lsb-release apt-transport-https wget gnupg2 netcat net-tools -y 
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
RUN wget -qO - https://packages.sury.org/php/apt.gpg | apt-key add -
RUN apt update
RUN apt install php5.6 php5.6-fpm -y
RUN apt install php5.6-gd php5.6-curl php5.6-xdebug php5.6-dom php5.6-iconv php5.6-mcrypt php5.6-pdo php5.6-pdo-mysql php5.6-simplexml php5.6-mbstring php5.6-soap -y

COPY conf/postfix.ini /usr/php5/fpm/conf.d/postfix.ini

# hash pcre extensions part of php core- installed
RUN apt autoclean

#RUN chown root:www-data -r /var/www/html
#RUN chmod 750 -r /var/www/html

COPY magento1/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

RUN mkdir -p /run/php/
RUN chown root:www-data /run/php/
RUN chmod 770 /run/php/



WORKDIR /var/www/html
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
