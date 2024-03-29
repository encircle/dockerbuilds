ARG BOOTSTRAP

FROM ${BOOTSTRAP}

ENV USER=encirsh
ENV UID=10022
ENV GID=10022

# package dependencies
RUN apk --update add --no-cache \
    nano \
    openssh \
    git \
    bash \
    coreutils \
    openssh-server-pam \
    openssh-sftp-server \
    shadow \
    curl \
    vim \
 && rm -rf /var/cache/apk/*

# ssh
COPY sshd_config /etc/ssh/sshd_config
RUN chmod 644 /etc/ssh/sshd_config

RUN ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key

# user and group
RUN addgroup -g 10022 ${USER} \
 && groupadd -f -g 10013 www-data

# create user
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/home/${USER}" \
    --ingroup "${USER}" \
    --uid "${UID}" \
    "${USER}"

# assign password to user
RUN echo "${USER}:$(head -c12 /dev/urandom | base64)" | chpasswd

# Add user to www-data
RUN usermod -aG 10013 "${USER}" \
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

EXPOSE 10022

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 750 /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
