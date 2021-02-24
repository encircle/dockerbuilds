FROM redmine:4.1.1-alpine

# build libraries for patron gem (required by redmine_bots plugin)
RUN apk add gcc \
            libc-dev \
            curl-dev \
            make

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore ruby
