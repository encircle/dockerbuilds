FROM mariadb:10.5.1
RUN ln -s -f /dev/null /root/.bash_history
RUN usermod -u 10012 mysql
RUN chown -R mysql:root /docker-entrypoint-initdb.d
RUN mkdir /etc/mysql/encircle.d
COPY conf/mysql/my.cnf /etc/mysql/my.cnf
COPY conf/mysql/encircle.d/encircle.cnf /etc/mysql/encircle.d/encircle.cnf
