FROM mariadb:10.5.28

# users and permissions
RUN ln -s -f /dev/null /root/.bash_history \
 && usermod -u 10012 mysql \
 && groupmod -g 10012 mysql \
 && chown -R mysql:root /docker-entrypoint-initdb.d \
 && chown mysql:mysql /var/log/mysql

# Hold mariadb version
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

# configs
COPY my.cnf /etc/mysql/my.cnf
COPY encircle.cnf /etc/mysql/conf.d/encircle.cnf

# encircle overrides dir
RUN mkdir /etc/mysql/encircle.d \
 && chown mysql:mysql /etc/mysql/encircle.d \
 && chown mysql:mysql /etc/mysql/mariadb.cnf \
 && chmod 640 /etc/mysql/mariadb.cnf \
 && chown -R mysql:mysql /etc/mysql/conf.d \
 && chmod -R 640 /etc/mysql/conf.d/*
 
ENV MARIADB_AUTO_UPGRADE=1