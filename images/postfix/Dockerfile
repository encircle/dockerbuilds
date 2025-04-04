FROM alpine:3.21

ENV TZ=
# Postfix myhostname
ENV HOSTNAME=
# Host that relays your msgs
ENV RELAYHOST=
# An (optional) username for the relay server
ENV RELAYHOST_USERNAME=
# An (optional) login password for the relay server
ENV RELAYHOST_PASSWORD=
# Define relay host TLS connection level. See http://www.postfix.org/postconf.5.html#smtp_tls_security_level for details.
# By default, the permissive level ("may") is used, if not defined.
ENV RELAYHOST_TLS_LEVEL=
# Allow domains from per Network ( default 127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 )
ENV MYNETWORKS=127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
# Allow any sender domains
ENV ALLOWED_SENDER_DOMAINS=
# Don't allow blank value for ALLOWED_SENDER_DOMAINS
ENV ALLOW_EMPTY_SENDER_DOMAINS=
# Attachments size. 0 means unlimited. Usually needs to be set if your relay host has an attachment size limit
ENV MESSAGE_SIZE_LIMIT=
# Enable additional debugging for connections to postfix
ENV INBOUND_DEBUGGING=

# Install supervisor, postfix
# Install postfix first to get the first account (101)
# Install opendkim second to get the second account (102)
RUN        true && \
           apk add --no-cache --upgrade cyrus-sasl cyrus-sasl-login && \
           apk add --no-cache postfix && \
           apk add --no-cache opendkim && \
           apk add --no-cache ca-certificates tzdata supervisor rsyslog && \
           apk add --no-cache --upgrade musl musl-utils && \
           (rm "/tmp/"* 2>/dev/null || true) && (rm -rf /var/cache/apk/* 2>/dev/null || true)

# Set up configuration
COPY       supervisord.conf /etc/supervisord.conf
COPY       rsyslog.conf /etc/rsyslog.conf
COPY       opendkim.conf /etc/opendkim/opendkim.conf
COPY       smtp_header_checks /etc/postfix/smtp_header_checks
COPY       commons.sh /
COPY	   run.sh /
COPY	   opendkim.sh /

# Set correct ownership
RUN chown opendkim:opendkim /opendkim.sh
RUN chown -R opendkim:opendkim /etc/opendkim \
    && chmod -R 750 /etc/opendkim

RUN        chmod +x /run.sh /opendkim.sh

# Custom scripts
RUN  mkdir /docker-init.db/
COPY sendgrid.sh /docker-init.db/
COPY ses.sh /docker-init.db/

# Set up volumes
VOLUME     [ "/var/spool/postfix", "/etc/postfix", "/etc/opendkim/keys" ]

# Run supervisord
USER       root
WORKDIR    /tmp

# Upgrade packages
RUN apk update \
 && apk upgrade

EXPOSE     587
CMD        ["/bin/sh", "-c", "/run.sh"]
