set -x

function configure_postfix() {

  DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  sed -i "s/\${SITE}/${DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini

}

function drupal_installed() {

  [[ -f /var/www/html/sites/default/settings.php ]]

}

function drupal_install() {

  set -eux

  cd /var/www/html
  curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz; \
  echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
  tar -xz --strip-components=1 -f drupal.tar.gz; \
  rm drupal.tar.gz; \
  chown -R www-data:www-data sites modules themes
  cd -

  cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php
  yes | drush site-install standard install_configure_form.update_status_module='array(FALSE,FALSE)'\
    --db-url="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${DB_HOST}/${MYSQL_DATABASE}"\
    --site-name="${TITLE}"\
    --account-name="${ADMIN_USER}"\
    --account-pass="${ADMIN_PASSWORD}"

}

function drupal_update() {

  # Get installed version, and intended version (from image)
  volume_version=$(drush status | grep 'Drupal version' | awk '{print $4}')
  image_version=$DRUPAL_VERSION

  # if an update is required
  if [[ $volume_version != $image_version ]]; then

    echo "Updating Drupal from $volume_version to $image_version"

    # Get core
    curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
    echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -
    tar -xz --strip-components=1 -f drupal.tar.gz
    rm drupal.tar.gz
    
    # Set permissions
    /usr/local/bin/permissions.sh

    # Update DB
    yes | drush updatedb
  fi 
}

function main() {

  configure_postfix

  # wait for the database connection
  db_status=1
  echo 'Waiting for DB to be available'
  while [[ $db_status != 0 ]]; do
    $(nc -z "$DB_HOST" 3306 > /dev/null 2>&1)
    db_status=$?
    sleep 3
  done

  # install if not installed
  drupal_installed || drupal_install

  # check for update if installed
  drupal_installed && drupal_update

  # enforce permissions
  /usr/local/bin/permissions.sh 2>/dev/null &

  # start the daemon
  php-fpm

}

main
