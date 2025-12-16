FROM mariadb:10.6

# users and permissions
RUN ln -s -f /dev/null /root/.bash_history \
 && usermod -u 10012 mysql \
 && groupmod -g 10012 mysql \
 && chown -R mysql:root /docker-entrypoint-initdb.d \
 && chown mysql:mysql /var/log/mysql

# --- Pin MariaDB packages so apt upgrade doesn't replace them ---
RUN echo "mariadb-backup hold" | dpkg --set-selections \
 && echo "mariadb-client-10.6 hold" | dpkg --set-selections \
 && echo "mariadb-client-core-10.6 hold" | dpkg --set-selections \
 && echo "mariadb-common hold" | dpkg --set-selections \
 && echo "mariadb-server" hold | dpkg --set-selections \
 && echo "mariadb-server-10.6 hold" | dpkg --set-selections \
 && echo "mariadb-server-core-10.6 hold" | dpkg --set-selections

# --- Upgrade OS packages without touching MariaDB ---
RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

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

# ----------------------
# Healthcheck
# ----------------------
HEALTHCHECK --interval=30s --timeout=5s --retries=5 \
    CMD mysqladmin ping -u root -p"$MYSQL_ROOT_PASSWORD" --socket=/var/run/mysqld/mysqld.sock || exit 1