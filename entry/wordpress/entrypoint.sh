set -x

# Only do this is Wordpress is already installed
if [[ -f /var/www/html/wp-config.php ]]; then

  # Get the installed Wordpress version
  VOLUME_VERSION="$(php -r 'require('"'"'/var/www/html/wp-includes/version.php'"'"'); echo $wp_version;')"
  echo "Volume version : "$VOLUME_VERSION

  # This is a predefined environment variable from
  # the official Docker image
  echo "WordPress version : "$WORDPRESS_VERSION

  # Wordpress official image checks for presence of
  # index and version php files and will not update
  # if they are present
  if [ $VOLUME_VERSION != $WORDPRESS_VERSION ]; then
    echo "Forcing WordPress code update..."
    rm -f /var/www/html/index.php
    rm -rf /var/www/html/wp-includes/version.php
  fi

fi

# Start crontab
/usr/sbin/crond -f -l 8 &

docker-entrypoint.sh php-fpm
