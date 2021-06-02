FROM redmine:4.1.1-alpine

# build libraries for patron gem (required by redmine_bots plugin)
RUN apk add gcc \
            libc-dev \
            curl-dev \
            make

# virus scanning
COPY scripts/nginx/clamd-hook.sh /usr/local/bin/clamd-hook.sh
COPY conf/redmine/attachment.rb /usr/src/redmine/app/models/attachment.rb
RUN apk add jq curl \
 && chmod 755 /usr/local/bin/clamd-hook.sh

# Upgrade packages
RUN apk update \
 && apk upgrade --ignore ruby
