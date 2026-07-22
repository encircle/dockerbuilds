#!/bin/bash
set -ex

function configure_postfix() {
  DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  tmpfile=$(mktemp)
  sed "s/\${SITE}/${DOMAIN}/g" /usr/local/etc/php/conf.d/postfix.ini > "$tmpfile"
  cp "$tmpfile" /usr/local/etc/php/conf.d/postfix.ini
  rm "$tmpfile"
}

function generate_settings() {
  # Redis: the 'tls://' host prefix is phpredis's own native TLS syntax
  # (drupal/redis's PhpRedis client factory passes the configured host
  # straight into phpredis's connect() call), so this should hold regardless
  # of exactly which drupal/redis module version is baked into the image --
  # but it hasn't been confirmed against a real build yet.
  cat > /var/www/html/web/sites/default/settings.php <<PHPEOF
<?php
\$databases['default']['default'] = [
  'database' => getenv('MYSQL_DATABASE'),
  'username' => getenv('MYSQL_USER'),
  'password' => getenv('MYSQL_PASSWORD'),
  'host' => getenv('DB_HOST'),
  'port' => 3306,
  'driver' => 'mysql',
  'prefix' => '',
  'pdo' => [
    PDO::MYSQL_ATTR_SSL_CA => '/var/www/html/web/sites/default/rds-ca.pem',
  ],
];

\$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT');

\$settings['redis.connection']['host'] = 'tls://' . getenv('REDIS_HOST');
\$settings['redis.connection']['port'] = getenv('REDIS_PORT');
\$settings['redis.connection']['password'] = getenv('REDIS_PASSWORD');
\$settings['cache']['default'] = 'cache.backend.redis';

// cache.backend.redis is needed VERY early -- before Drupal's normal
// module/container system has loaded -- since it's also used as the
// container definition cache itself, not just a regular cache bin.
// Confirmed live: without this block, bootstrap fails with "You have
// requested a non-existent service 'cache.backend.redis'" even with
// drupal/redis correctly present in the codebase and enabled.
\$class_loader->addPsr4('Drupal\\\\redis\\\\', 'modules/contrib/redis/src');

\$settings['bootstrap_container_definition'] = [
  'parameters' => [],
  'services' => [
    'redis.factory' => [
      'class' => 'Drupal\redis\ClientFactory',
    ],
    'cache.backend.redis' => [
      'class' => 'Drupal\redis\Cache\CacheBackendFactory',
      'arguments' => ['@redis.factory', '@cache_tags_provider.container', '@serialization.phpserialize'],
    ],
    'cache.container' => [
      'class' => '\Drupal\redis\Cache\PhpRedis',
      'factory' => ['@cache.backend.redis', 'get'],
      'arguments' => ['container'],
    ],
    'cache_tags_provider.container' => [
      'class' => 'Drupal\redis\Cache\RedisCacheTagsChecksum',
      'arguments' => ['@redis.factory'],
    ],
    'serialization.phpserialize' => [
      'class' => 'Drupal\Component\Serialization\PhpSerialize',
    ],
  ],
];

\$settings['reverse_proxy'] = TRUE;
\$settings['trusted_host_patterns'] = ['^' . preg_quote(getenv('SITE'), '/') . '\$'];

\$settings['config_sync_directory'] = '/var/www/html/config/sync';
PHPEOF
  chown root:www-data /var/www/html/web/sites/default/settings.php
  chmod 640 /var/www/html/web/sites/default/settings.php
}

function wait_for_db() {
  echo 'Waiting for DB to be available'
  while ! nc -z "$DB_HOST" 3306 > /dev/null 2>&1; do
    sleep 3
  done
}

function run_updates() {
  # Every instance in the fleet runs this on boot, but only one may ever
  # actually run `drush updb`/`config:import` at a time -- a blue/green
  # rollout brings up multiple APP instances at once, all on the same new
  # codebase and config, and neither Drupal's update system nor its config
  # importer protect against two hosts applying the same DB changes
  # concurrently. GET_LOCK/RELEASE_LOCK is
  # session-scoped in MariaDB, so it must be acquired, held, and released
  # over one single persistent connection (a `mysql -e` per statement would
  # release it immediately on disconnect) -- a bash coproc keeps that one
  # connection open across the external `drush updb` call. As a bonus, if
  # this instance dies mid-update, the lock is dropped automatically when
  # its connection closes, rather than staying stuck forever.
  local lock_name='drupal_updb'
  local lock_timeout=300
  local got_lock

  coproc MYSQL_LOCK {
    mariadb --ssl -h "$DB_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        "$MYSQL_DATABASE" -N -B
  }

  echo "SELECT GET_LOCK('${lock_name}', ${lock_timeout});" >&"${MYSQL_LOCK[1]}"
  read -r -u "${MYSQL_LOCK[0]}" got_lock

  if [ "$got_lock" = "1" ]; then
    drush -r /var/www/html/web updb -y
    drush -r /var/www/html/web config:import -y
    drush -r /var/www/html/web cache:rebuild
    echo "SELECT RELEASE_LOCK('${lock_name}');" >&"${MYSQL_LOCK[1]}"
    read -r -u "${MYSQL_LOCK[0]}" _
  else
    echo "drupal_updb lock held by another instance (or acquire timed out) -- skipping updates on this boot"
  fi

  echo "quit" >&"${MYSQL_LOCK[1]}"
  wait "$MYSQL_LOCK_PID" 2>/dev/null || true
}

function main() {
  configure_postfix
  generate_settings
  wait_for_db
  run_updates

  php-fpm
}

main
