set -x

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

  # if we are using an esr release - add civicrm gitlab repo
  if [[ "$CIVICRM_VERSION" = *+esr ]]; then
    ssh-keyscan -H lab.civicrm.org > ~/.ssh/known_hosts
    composer config repositories.esr-core vcs git@lab.civicrm.org:esr/core.git
    composer config repositories.esr-packages vcs git@lab.civicrm.org:esr/packages.git
    composer config repositories.esr-drupal-8 vcs git@lab.civicrm.org:esr/drupal-8.git
  fi

  #civi requirements
  composer config extra.enable-patching true
  composer config minimum-stability dev
  composer config --no-plugins allow-plugins.cweagans/composer-patches true
  composer config --no-plugins allow-plugins.civicrm/civicrm-asset-plugin true
  composer config --no-plugins allow-plugins.civicrm/composer-downloads-plugin true
  composer config --no-plugins allow-plugins.civicrm/composer-compile-plugin true
  composer config extra.compile-mode all
  composer require civicrm/civicrm-{core,packages,drupal-8}:"${CIVICRM_VERSION}"

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

    composer require civicrm/civicrm-{core,packages,drupal-8}:"${CIVICRM_VERSION}" -W
    cv upgrade:db
    cv ext:upgrade-db
  fi
}

#uses https://github.com/localgovdrupal/localgov_project/
function drupal_install() {
  set -eux

  #create project
  cd $INSTALL_DIR
  composer create-project localgovdrupal/localgov-project:=$LOCALGOVPROJECT_VERSION site
  chmod 750 $INSTALL_DIR/site
  chown root:www-data site
  chown -R www-data:www-data $INSTALL_DIR/site/web/sites $INSTALL_DIR/site/web/modules $INSTALL_DIR/site/web/themes

  #copy default settings file
  cp $INSTALL_DIR/site/web/sites/default/default.settings.php $INSTALL_DIR/site/web/sites/default/settings.php

  #install site
  yes | /usr/local/bin/drush site-install localgov install_configure_form.enable_update_status_emails=NULL \
    --db-url="mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${DB_HOST}/${MYSQL_DATABASE}"\
    --site-name="${TITLE}"\
    --account-name="${ADMIN_USER}"\
    --account-pass="${ADMIN_PASSWORD}"

  #turn off preprocessors
  drush -y config-set system.performance css.preprocess 0
  drush -y config-set system.performance js.preprocess 0
}

function drupal_update() {
  # localgov_volume_version=$(composer show 'localgovdrupal/localgov' | sed -n '/versions/s/^[^0-9]\+\([^,]\+\).*$/\1/p')
  # localgov_image_version=$LOCALGOVPROJECT_VERSION

  # if [[ "$localgov_volume_version" != $localgov_image_version ]]; then
  #   composer require "localgovdrupal/localgov:=${LOCALGOVPROJECT_VERSION}" --with-all-dependencies
  # fi

  volume_version=$(drush status | grep 'Drupal version' | awk '{print $4}')
  image_version=$DRUPAL_VERSION

  # if [[ "$volume_version" != $image_version ]]; then
  #   composer require "drupal/core-composer-scaffold:=${DRUPAL_VERSION}" --with-all-dependencies
  #   composer require "drupal/core-project-message:=${DRUPAL_VERSION}" --with-all-dependencies
  #   composer require "drupal/core-recommended:=${DRUPAL_VERSION}" --with-all-dependencies

  #   /usr/local/bin/drush updatedb -y
  #   /usr/local/bin/drush cache:rebuild
  # fi
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

  civi=${CIVI:-False}
  if [ "$civi" = true ]; then
    civi_installed || civi_install

    civi_installed && civi_update
  fi

  webroot_setup

  # enforce permissions
  /usr/local/bin/permissions.sh 2>/dev/null &

  # start the daemon
  php-fpm

}

main

