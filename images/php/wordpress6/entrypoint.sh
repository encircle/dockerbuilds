set -x

wordpress_installed() {
  [[ -f /var/www/html/wp-config.php ]]
}

civi_installed() {
  [[ -f /var/www/html/wp-content/plugins/civicrm/civicrm/civicrm-version.php ]]
}

install_wordpress() {

  wp --allow-root core download \
     --path=/var/www/html \
     --version="${WORDPRESS_VERSION}"

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
     --url="https://${DOMAIN}" \
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

function install_civi(){
  cd /var/www/html/wp-content/plugins
  wget https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-wordpress.zip

  # DL l10n
  wget https://download.civicrm.org/civicrm-${CIVICRM_VERSION}-l10n.tar.gz

  #unzip civi
  unzip civicrm-${CIVICRM_VERSION}-wordpress.zip

  # unzip the new l10n
  tar -xzf civicrm-${CIVICRM_VERSION}-l10n.tar.gz

  cd /var/www/html
  cv core:install --cms-base-url="https://${DOMAIN}" --lang="en_GB"
}

function upgrade_civi(){
  #https://gist.github.com/em-piguet/4ace59fdbcbc74cbcb14064dd90fadb4
  echo "upgrade"
  # VOLUME_VERSION="$(php -r 'require('"'"'/var/www/html/wp-content/plugins/civicrm/civicrm.php'"'"'); echo $CIVICRM_PLUGIN_VERSION;')"
  # echo "Civi volume version : $VOLUME_VERSION"
  # echo "Civi version : $CIVICRM_VERSION"


  # cd /var/www/html/wp-content/plugins

  # # DL main plugin
  # wget https://download.civicrm.org/civicrm-$civi_version-wordpress.zip

  # # DL l10n
  # wget https://download.civicrm.org/civicrm-$civi_version-l10n.tar.gz

}

configure_postfix() {
  DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  sed -i "s/\${SITE}/${DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini
}

function main() {
  # Configure postfix
  configure_postfix

  # wait for the database connection
  db_status=1
  while [[ $db_status != 0 ]]; do
    echo 'Waiting for DB to be available'
    $(nc -z "$WORDPRESS_DB_HOST" 3306 > /dev/null 2>&1)
    db_status=$?
    sleep 3
  done

  # Install wordpress if not installed
  wordpress_installed || install_wordpress

  # check/apply update if installed
  wordpress_installed && upgrade_wordpress

  civi=${CIVI:-False}
  if [ "$civi" = true ]; then
    # Install civi if not installed
    civi_installed || install_civi

    # check/apply update if installed
    civi_installed && upgrade_civi
  fi

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
}

main