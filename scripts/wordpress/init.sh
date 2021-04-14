set -x

wordpress_installed() {
  [[ -f /var/www/html/wp-config.php ]]
}

install_wordpress() {
  cd /var/www/html && \
  wp --allow-root core install --path=/var/www/html \
     --url="${DOMAIN}" \
     --title="${TITLE}" \
     --admin_user="${ADMIN_USER}" \
     --admin_password="${ADMIN_PASSWORD}" \
     --admin_email="${ADMIN_EMAIL}"
}

upgrade_wordpress() {

  VOLUME_VERSION="$(php -r 'require('"'"'/var/www/html/wp-includes/version.php'"'"'); echo $wp_version;')"
  echo "Volume version : $VOLUME_VERSION"
  echo "WordPress version : $WORDPRESS_VERSION"

  if [ "$VOLUME_VERSION" != "$WORDPRESS_VERSION" ]; then
    echo "Forcing WordPress code update..."
    wp --allow-root core update --version="$WORDPRESS_VERSION"
  fi

}

set_config() {
  [[ -f /var/www/html/wp-config.php ]] || return 1
  sed -i -E s/\(\'DB_NAME\'.*\)/define\(\'DB_NAME\'\,\ \"$WORDPRESS_DB_NAME\"\)/ /var/www/hmtl/wp-config.php
  sed -i -E s/\(\'DB_USER\'.*\)/define\(\'DB_USER\'\,\ \"$WORDPRESS_DB_USER\"\)/ /var/www/hmtl/wp-config.php
  sed -i -E s/\(\'DB_PASSWORD\'.*\)/define\(\'USER_PASS\'\,\ \"$WORDPRESS_DB_PASSWORD\"\)/ /var/www/hmtl/wp-config.php
  sed -i -E s/\(\'DB_HOST\'.*\)/define\(\'DB_HOST\'\,\ \"$WORDPRESS_DB_HOST\"\)/ /var/www/hmtl/wp-config.php
  sed -E s/$table_prefix\ =\ .*\;/$table_prefix=$WORDPRESS_TABLE_PREFIX/
}

configure_postfix() {
  sed -i "s/\${SITE}/${DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini
}

DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')

# wait for the database connection
wait-for -t 60 ${WORDPRESS_DB_HOST}:3306 &&

  (
    set -eux
    install_wordpress
  ) || echo 'No database connection, cannot install Wordpress. Installation aborted!'

# Only run if wordpress is installed
wordpress_installed && upgrade_wordpress

# Configure postfix
configure_postfix

# Configure Wordpress
set_config || 'wp config is missing'

# permissions
/usr/local/bin/permissions.sh

# Start crontab
/usr/sbin/crond -f -l 8 &
