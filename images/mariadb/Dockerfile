FROM mariadb:10.5.3

RUN ln -s -f /dev/null /root/.bash_history

RUN usermod -u 10012 mysql \
 && groupmod -g 10012 mysql \
 && chown mysql:mysql /var/log/mysql

RUN mkdir /etc/mysql/encircle.d

COPY conf/mysql/my.cnf /etc/mysql/my.cnf
COPY conf/mysql/encircle.d/encircle.cnf /etc/mysql/encircle.d/encircle.cnf
