#!/bin/bash
set -ex

function configure_postfix() {
  DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  sed -i "s/\${SITE}/${DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini
}

function drupal_installed() {
  [[ -f $INSTALL_DIR/site/web/sites/default/settings.php ]]
}

function civi_installed() {
  [[ -f $INSTALL_DIR/site/vendor/civicrm/civicrm-core/civicrm-version.php ]]
}

function civi_install(){
  set -eux

  #civi requirements
  composer config extra.enable-patching true
  composer config minimum-stability dev
  composer remove drush/drush
  composer config --no-plugins allow-plugins.cweagans/composer-patches true
  composer config --no-plugins allow-plugins.civicrm/civicrm-asset-plugin true
  composer config --no-plugins allow-plugins.civicrm/composer-downloads-plugin true
  composer config --no-plugins allow-plugins.civicrm/composer-compile-plugin true
  composer config extra.compile-mode all

  # if we are using an esr release - add civicrm gitlab repo
  if [[ "$CIVICRM_VERSION" = *+esr ]]; then
    ssh-keyscan -H lab.civicrm.org > ~/.ssh/known_hosts
    composer config repositories.esr-core vcs git@lab.civicrm.org:esr/core.git
    composer config repositories.esr-packages vcs git@lab.civicrm.org:esr/packages.git
    composer config repositories.esr-drupal-8 vcs git@lab.civicrm.org:esr/drupal-8.git
    
  fi

  #require civi
  composer require civicrm/civicrm-{core,packages,drupal-8}:"${CIVICRM_VERSION}"
  composer require drush/drush

  #civi install onto site
  cv core:install --cms-base-url="https://${SITE}" --lang="en_GB"
  cv upgrade:db
  cv ext:upgrade-db
}

function civi_update(){
  volume_civi_version=$(composer show 'civicrm/civicrm-core' | sed -n '/versions/s/^[^0-9]\+\([^,]\+\).*$/\1/p')
  image_civi_version=$CIVICRM_VERSION

  if [[ "$volume_civi_version" != $image_civi_version ]]; then

    # if we are using an esr release - add civicrm gitlab repo
    if [[ "$CIVICRM_VERSION" = *+esr ]]; then
      ssh-keyscan -H lab.civicrm.org > ~/.ssh/known_hosts
      composer config repositories.esr-core vcs git@lab.civicrm.org:esr/core.git
      composer config repositories.esr-packages vcs git@lab.civicrm.org:esr/packages.git
      composer config repositories.esr-drupal-8 vcs git@lab.civicrm.org:esr/drupal-8.git
    fi

    #require updated civi
    composer require civicrm/civicrm-{core,packages,drupal-8}:"${CIVICRM_VERSION}" --with-all-dependencies

    cv upgrade:db
    cv ext:upgrade-db
  fi
}

function drupal_install() {
  set -eux

  cd $INSTALL_DIR
  composer create-project drupal/recommended-project:"${DRUPAL_VERSION:-^10}" site
  chmod 750 $INSTALL_DIR/site
  chown root:www-data site
  chown -R www-data:www-data $INSTALL_DIR/site/web/sites $INSTALL_DIR/site/web/modules $INSTALL_DIR/site/web/themes

  cd $INSTALL_DIR/site
  composer require drush/drush

  cp $INSTALL_DIR/site/web/sites/default/default.settings.php $INSTALL_DIR/site/web/sites/default/settings.php
  yes | $INSTALL_DIR/site/vendor/bin/drush site-install standard install_configure_form.update_status_module='array(FALSE,FALSE)'\
    --db-url="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${DB_HOST}/${MYSQL_DATABASE}"\
    --site-name="${TITLE}"\
    --account-name="${ADMIN_USER}"\
    --account-pass="${ADMIN_PASSWORD}"
}

function drupal_update() {
  volume_version=$($INSTALL_DIR/site/vendor/bin/drush status | grep 'Drupal version' | awk '{print $4}')
  image_version=$DRUPAL_VERSION

  if [[ "$volume_version" != $image_version ]]; then
    composer require "drupal/core-composer-scaffold:=${DRUPAL_VERSION}" --with-all-dependencies
    composer require "drupal/core-project-message:=${DRUPAL_VERSION}" --with-all-dependencies
    composer require "drupal/core-recommended:=${DRUPAL_VERSION}" --with-all-dependencies

    $INSTALL_DIR/site/vendor/bin/drush updatedb -y
    $INSTALL_DIR/site/vendor/bin/drush cache:rebuild
  fi
}

function webroot_setup() {
  # /var/www/html may be a Docker mount point and cannot be removed directly.
  # Try to replace it with a symlink; if that fails, symlink the site dir inside it.
  if [ ! -L /var/www/html ]; then
    rm -rf /var/www/html 2>/dev/null \
      && ln -s $INSTALL_DIR /var/www/html \
      || ln -sfn $INSTALL_DIR/site /var/www/html/site
  fi
  chown -h root:www-data $WEBROOT/
  chown root:www-data $INSTALL_DIR/site/web
  chmod 750 $WEBROOT/
  chmod 750 $INSTALL_DIR/site/web
}

function main() {
  INSTALL_DIR=/var/src/drupal
  WEBROOT=/var/www/html/site/web
  
  configure_postfix

  # wait for the database connection
  echo 'Waiting for DB to be available'
  while ! nc -z "$DB_HOST" 3306 > /dev/null 2>&1; do
    sleep 3
  done

  # install if not installed
  if ! drupal_installed; then
    drupal_install
  fi

  # check/apply update if installed
  #if drupal_installed; then
  #  drupal_update
  #fi

  civi=${CIVI:-False}
  if [ "$civi" = true ]; then
    if ! civi_installed; then
      civi_install
    fi

    #if civi_installed; then
    #  civi_update
    #fi
  fi

  webroot_setup

  # enforce permissions
  /usr/local/bin/permissions.sh 2>/dev/null &

  # start cron daemon
  /usr/sbin/crond -f -l 8 &

  # start the daemon
  php-fpm

}

main
