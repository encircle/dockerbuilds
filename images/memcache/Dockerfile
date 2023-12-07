FROM alpine:3.18.5

COPY entrypoint.sh /usr/local/bin
RUN apk --no-cache add memcached && chmod +x /usr/local/bin/entrypoint.sh

# Upgrade packages
RUN apk update \
 && apk upgrade

USER memcached
EXPOSE 11211
CMD ["/usr/local/bin/entrypoint.sh"]
