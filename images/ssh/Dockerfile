FROM alpine:3.12

ENV USER=encirsh
ENV UID=10022
ENV GID=10022

RUN apk --update add --no-cache openssh git bash openssh-server-pam shadow \
 && rm -rf /var/cache/apk/*

COPY conf/ssh/sshd_config /etc/ssh/sshd_config
RUN chmod 644 /etc/ssh/sshd_config

RUN /usr/bin/ssh-keygen -A
RUN ssh-keygen -t rsa -b 4096 -f  /etc/ssh/ssh_host_key

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

RUN apk add sudo \
 && echo "${USER} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
 && chmod 0440 /etc/sudoers.d/$USER

RUN rm -f /sbin/apk; \
    rm -rf /etc/apk; \
    rm -rf /lib/apk; \
    rm -rf /usr/share/apk; \
    rm -rf /var/lib/apk;

EXPOSE 10022

COPY entry/ssh/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 750 /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
