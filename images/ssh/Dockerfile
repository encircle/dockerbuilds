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

RUN rm -f /sbin/apk; \
    rm -rf /etc/apk; \
    rm -rf /lib/apk; \
    rm -rf /usr/share/apk; \
    rm -rf /var/lib/apk;

USER 10022
RUN ssh-keygen -t rsa -f /home/${USER}/.ssh/id_rsa -q -P ""
RUN cat /home/${USER}/.ssh/id_rsa.pub > /home/${USER}/.ssh/authorized_keys

USER 0
EXPOSE 10022
CMD ["/usr/sbin/sshd", "-D"]
