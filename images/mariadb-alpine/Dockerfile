FROM alpine:3.12

RUN ln -s -f /dev/null /root/.bash_history

RUN apk add --no-cache shadow \
                       mariadb \
                       mariadb-client \
                       mariadb-server-utils \
                       pwgen \
 && usermod -u 10012 mysql \
 && groupmod -g 10012 mysql \
 && rm -f /var/cache/apk/* \
 && apk del shadow

ADD entry/mariadb-alpine/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN mkdir /docker-entrypoint-initdb.d \
 && mkdir -p /scripts/pre-exec.d \
 && mkdir -p /scripts/pre-init.d \
 && chmod -R 755 /scripts

COPY conf/mysql/my.cnf /etc/mysql/my.cnf
COPY conf/mysql/encircle.cnf /etc/mysql/conf.d/encircle.cnf

EXPOSE 3306

VOLUME ["/var/lib/mysql"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
