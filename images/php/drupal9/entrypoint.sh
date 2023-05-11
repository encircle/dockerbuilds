set -x

function configure_postfix() {

  DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  sed -i "s/\${SITE}/${DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini

}

function drupal_installed() {

  [[ -f $INSTALL_DIR/site/web/sites/default/settings.php ]]

}

function drupal_install() {

  set -eux

  cd $INSTALL_DIR
  composer create-project drupal/recommended-project site
  chmod 750 $INSTALL_DIR/site
  chown root:www-data site
  chown -R www-data:www-data $INSTALL_DIR/site/web/sites $INSTALL_DIR/site/web/modules $INSTALL_DIR/site/web/themes

  cd $INSTALL_DIR/site
  composer require drush/drush:~10

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
    ${INSTALL_DIR}/site/vendor/bin/drush cache:rebuild
  fi

  volume_civi_version=$(composer show 'civicrm/civicrm-core' | sed -n '/versions/s/^[^0-9]\+\([^,]\+\).*$/\1/p')
  image_civi_version=$CIVICRM_VERSION
  if [[ "$volume_civi_version" != $image_civi_version ]]; then

    # if we are using an esr release - add civicrm gitlab repo
    if [[ "$CIVICRM_VERSION" == *-esr ]]; then
      ssh -o "StrictHostKeyChecking no" git@lab.civicrm.org
      composer config repositories.esr-core vcs git@lab.civicrm.org:esr/core.git
      composer config repositories.esr-packages vcs git@lab.civicrm.org:esr/packages.git
      composer config repositories.esr-drupal-8 vcs git@lab.civicrm.org:esr/drupal-8.git
    fi
    composer require "civicrm/civicrm-core:${CIVICRM_VERSION}" "civicrm/civicrm-drupal-8:${CIVICRM_VERSION}" "civicrm/civicrm-packages:${CIVICRM_VERSION}" -W
    composer require "civicrm/cv:^0.3.40"
    cv upgrade:db
    cv ext:upgrade-db
  fi
}

function webroot_setup() {

  rm -rf /var/www/html
  ln -s $INSTALL_DIR /var/www/html
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
  db_status=1
  echo 'Waiting for DB to be available'
  while [[ $db_status != 0 ]]; do
    $(nc -z "$DB_HOST" 3306 > /dev/null 2>&1)
    db_status=$?
    sleep 3
  done

  # install if not installed
  drupal_installed || drupal_install

  # check/apply update if installed
  drupal_installed && drupal_update

  webroot_setup

  # enforce permissions
  /usr/local/bin/permissions.sh 2>/dev/null &

  # start the daemon
  php-fpm

}

main
