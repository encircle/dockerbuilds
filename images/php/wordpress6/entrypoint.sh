#!/bin/bash
set -ex

wordpress_installed() {
  [[ -f /var/www/html/wp-config.php ]]
}

install_wordpress() {

  wp --allow-root core download \
     --path=/var/www/html

  wp --allow-root config create \
     --path=/var/www/html \
     --skip-check \
     --dbname="${WORDPRESS_DB_NAME}" \
     --dbuser="${WORDPRESS_DB_USER}" \
     --dbpass="${WORDPRESS_DB_PASSWORD}" \
     --dbhost="${WORDPRESS_DB_HOST}" \
     --dbprefix="${WORDPRESS_TABLE_PREFIX}"

  wp --allow-root core install \
     --path=/var/www/html \
     --url="${DOMAIN}" \
     --title="${TITLE}" \
     --admin_user="${ADMIN_USER}" \
     --admin_password="${ADMIN_PASSWORD}" \
     --admin_email="${ADMIN_EMAIL}"

}

# upgrade_wordpress() {

#   VOLUME_VERSION="$(php -r 'require('"'"'/var/www/html/wp-includes/version.php'"'"'); echo $wp_version;')"
#   echo "Volume version : $VOLUME_VERSION"
#   echo "WordPress version : $WORDPRESS_VERSION"

#   if [ "$VOLUME_VERSION" != "$WORDPRESS_VERSION" ]; then
#     echo "Forcing WordPress code update..."
#     wp --allow-root core update --version="$WORDPRESS_VERSION"
#   fi

# }

configure_postfix() {
  PRIMARY_DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  sed -i "s/\${SITE}/${PRIMARY_DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini
}

# wait for the database connection
echo 'Waiting for DB to be available'
while ! nc -z "$WORDPRESS_DB_HOST" 3306 > /dev/null 2>&1; do
  sleep 3
done

# Only run if wordpress is not installed
if ! wordpress_installed; then
  install_wordpress
fi

# Only run if wordpress is installed
#if wordpress_installed; then
#  upgrade_wordpress
#fi

# Configure postfix
configure_postfix

# Configure Wordpress
wp --allow-root config create \
   --force \
   --path=/var/www/html \
   --skip-check \
   --dbname="${WORDPRESS_DB_NAME}" \
   --dbuser="${WORDPRESS_DB_USER}" \
   --dbpass="${WORDPRESS_DB_PASSWORD}" \
   --dbhost="${WORDPRESS_DB_HOST}" \
   --dbprefix="${WORDPRESS_TABLE_PREFIX}" \
   --extra-php="${WORDPRESS_CONFIG_EXTRA}"

# permissions
/usr/local/bin/permissions.sh 2>/dev/null &

# Start crontab
/usr/sbin/crond -f -l 8 &

# Run PHP
php-fpm