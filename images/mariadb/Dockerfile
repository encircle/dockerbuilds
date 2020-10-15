FROM mariadb:10.5.3

RUN ln -s -f /dev/null /root/.bash_history
RUN usermod -u 10012 mysql
RUN chown -R mysql:root /docker-entrypoint-initdb.d
RUN chown -R mysql:root /var/log/mysql

RUN usermod -u 10012 mysql \
 && groupmod -g 10012 mysql \
 && chown mysql:mysql /var/log/mysql

# Fix mariadb version
RUN echo mariadb-backup hold | dpkg --set-selections \
 && echo mariadb-client-10.5 hold | dpkg --set-selections \
 && echo mariadb-client-core-10.5 hold | dpkg --set-selections \
 && echo mariadb-common hold | dpkg --set-selections \
 && echo mariadb-server hold | dpkg --set-selections \
 && echo mariadb-server-10.5 hold | dpkg --set-selections \
 && echo mariadb-server-core-10.5 hold | dpkg --set-selections

# Upgrade packages
RUN apt update -y \
 && apt upgrade -y

COPY conf/mysql/my.cnf /etc/mysql/my.cnf
COPY conf/mysql/encircle.cnf /etc/mysql/conf.d/encircle.cnf
RUN mkdir /etc/mysql/encircle.d \
 && chown mysql:mysql /etc/mysql/encircle.d
