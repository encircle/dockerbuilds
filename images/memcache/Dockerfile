FROM alpine:3.21

COPY entrypoint.sh /usr/local/bin
RUN apk --no-cache add memcached && chown memcached:memcached /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

# Upgrade packages
RUN apk update \
 && apk upgrade

USER memcached
EXPOSE 11211
CMD ["/usr/local/bin/entrypoint.sh"]
