FROM encircle/wordpress:latest

# Civicrm CLI
RUN curl -LsS https://download.civicrm.org/cv/cv.phar -o /usr/local/bin/cv \
 && chmod +x /usr/local/bin/cv

# CiviCRM
RUN wget -P / https://download.civicrm.org/civicrm-5.32.2-wordpress.zip

# packages required by extensions
RUN apk add --no-cache libxml2-dev \
       icu-dev \
       libzip-dev

# Civicrm required extensions
RUN docker-php-ext-install bcmath \
       dom \
       mbstring \
       intl \
       zip

# Upgrade packages
RUN apk update \
 && apk upgrade

# scripts
COPY scripts/wordpress-civicrm/wait-for /usr/local/bin
COPY scripts/wordpress-civicrm/init.sh /entrypoint.d/init.sh
RUN chmod 750 /usr/local/bin/wait-for
RUN chmod 750 /entrypoint.d/init.sh
