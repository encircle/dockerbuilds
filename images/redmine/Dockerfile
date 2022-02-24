FROM redmine:4.1.6-alpine

# build libraries for patron gem (required by redmine_bots plugin)
RUN apk add gcc \
            libc-dev \
            curl-dev \
            make

# virus scanning
COPY clamd-hook.sh /usr/local/bin/clamd-hook.sh
COPY attachment.rb /usr/src/redmine/app/models/attachment.rb

RUN apk add jq curl \
 && chmod 755 /usr/local/bin/clamd-hook.sh

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore ruby
