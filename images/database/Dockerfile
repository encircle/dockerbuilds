FROM mariadb:10.5.1
RUN ln -s -f /dev/null /root/.bash_history
RUN chmod 777 /docker-entrypoint-initdb.d
RUN mkdir /etc/mysql/encircle.d
COPY conf/mysql/my.cnf /etc/mysql/my.cnf
COPY conf/mysql/encircle.d/encircle.cnf /etc/mysql/encircle.d/encircle.cnf
