FROM alpine:3.12

ENV USER=encirsh
ENV UID=10022
ENV GID=10022

# package dependencies
RUN apk --update add --no-cache \
    openssh \
    git \
    bash \
    openssh-server-pam \
    shadow \
    php \
    php-cli \
    php-common \
    php-mysqli \
    php-curl \
    php-gd \
    php-bz2 \
    php-json \
    php-tidy \
    php-mbstring \
    php-phar \
    php-iconv \
    php-pdo \
    php-pdo_mysql \
    php-session \
    php-tokenizer \
    mysql-client \
    curl \
 && rm -rf /var/cache/apk/*

# ssh
COPY conf/ssh/sshd_config /etc/ssh/sshd_config
RUN chmod 644 /etc/ssh/sshd_config

RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key

# user and group
RUN addgroup -g 10022 ${USER}

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/${USER}" \
    --ingroup "${USER}" \
    --uid "${UID}" \
    ${USER}

RUN addgroup -g 10013 www-data \
 && usermod -aG 10013 "${USER}" \
 && apk del shadow

# passwordless sudo
RUN apk add sudo \
 && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
 && chmod 0440 /etc/sudoers.d/$USER

# remove apk
RUN rm -f /sbin/apk; \
    rm -rf /etc/apk; \
    rm -rf /lib/apk; \
    rm -rf /usr/share/apk; \
    rm -rf /var/lib/apk;

# drush
ENV DRUSH_VERSION 8.3.5
RUN wget https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar \
 && mv drush.phar /usr/local/bin/drush \
 && chmod 750 /usr/local/bin/drush \
 && chown root:"${UID}" /usr/local/bin/drush

# wp cli
RUN cd /tmp && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && mv /tmp/wp-cli.phar /usr/local/bin/wp \
 && chmod 750 /usr/local/bin/wp \
 && chown root:"${UID}" /usr/local/bin/wp

# permissions scripts
COPY scripts/drupal/permissions.sh /usr/local/bin/permissions-drupal.sh
COPY scripts/wordpress/permissions.sh /usr/local/bin/permissions-wordpress.sh
RUN chmod 750 /usr/local/bin/permissions*.sh

EXPOSE 10022

COPY entry/ssh/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 750 /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
