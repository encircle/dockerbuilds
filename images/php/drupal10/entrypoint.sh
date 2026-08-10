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
  # of exactly which drupal/redis module version is baked into the image.
  # Conditional on REDIS_TLS rather than always-on: AWS ElastiCache requires
  # TLS (Invariant #3), but a local `docker compose up` typically runs a
  # bare redis container with no TLS support at all -- REDIS_TLS lets the
  # same settings.php logic work against both without a separate code path.
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

\$settings['redis.connection']['host'] = (getenv('REDIS_TLS') === 'true' ? 'tls://' : '') . getenv('REDIS_HOST');
\$settings['redis.connection']['port'] = getenv('REDIS_PORT');
\$settings['redis.connection']['password'] = getenv('REDIS_PASSWORD');

// Deliberately scoped to specific bins, NOT \$settings['cache']['default'].
// A blanket default routes EVERY bin through Redis -- including
// cache.container/cache.bootstrap, which Drupal's real (post-bootstrap)
// container needs for near enough every operation, drush commands
// included. That means any drush command (updb, config:import, cron,
// anything) hard-fails with "You have requested a non-existent service
// 'cache.backend.redis'" whenever the redis module isn't enabled in the
// current database yet -- which is exactly the state a freshly-restored
// or not-yet-config-imported database is in. Confirmed live: this blocked
// updb, which blocked config:import from ever running, which is the one
// thing that would have enabled the module -- a real chicken-and-egg.
// Scoping to just the bins that matter for request performance means
// cache.container/cache.bootstrap/cache.default fall through to Drupal's
// own database backend instead, which needs no module and no live Redis
// connection at all, so drush operations always work regardless of
// whether redis happens to be enabled yet.
\$settings['cache']['bins']['render'] = 'cache.backend.redis';
\$settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.redis';

// cache.backend.redis is needed VERY early -- before Drupal's normal
// module/container system has loaded -- since bootstrap_container_definition
// below also uses it for the container definition cache itself, not just
// a regular cache bin. This part is independent of the bin-scoping above:
// it's a separate, hand-wired bootstrap-only container, not affected by
// \$settings['cache']['bins']. Confirmed live: without this block, bootstrap
// fails with "You have requested a non-existent service
// 'cache.backend.redis'" even with drupal/redis correctly present in the
// codebase and enabled.
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
  # concurrently. GET_LOCK is session-scoped in MariaDB and auto-releases
  # the moment its connection closes (a `mysql -e` per statement would
  # release it immediately, before the lock could do anything useful) -- a
  # bash coproc holds one connection open across the whole update sequence,
  # and closing it at the end (via `quit`) is what releases the lock, not
  # an explicit RELEASE_LOCK query (see below -- that hangs in practice).
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
    # core.extension.yml is Drupal's own marker for "this directory holds a
    # real config export" -- config:import correctly refuses to run against
    # an empty/missing config_sync_directory (it would otherwise delete all
    # existing config), but that refusal is fatal to this script under
    # set -e. An empty config/sync is an expected state (ped-drupal's
    # config hasn't been baked into every image yet), not a real failure,
    # so skip the step entirely rather than crash the whole container over it.
    if [ -f /var/www/html/config/sync/core.extension.yml ]; then
      drush -r /var/www/html/web config:import -y
    else
      echo "config/sync has no core.extension.yml -- nothing to import, skipping"
    fi
    drush -r /var/www/html/web cache:rebuild
    # No explicit RELEASE_LOCK query here -- confirmed live, this hangs:
    # after the real wall-clock time updb/config:import/cache:rebuild take
    # as separate processes, the long-idle coproc connection can be silently
    # dropped (NAT/connection-tracking idle timeout or similar) without the
    # client noticing, so the read for this query's response never returns.
    # GET_LOCK already auto-releases the moment its session disconnects, and
    # we're about to send `quit` and close this connection anyway -- that's
    # sufficient, and removes the failure point entirely instead of working
    # around it.
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

  # --nodaemonize: without it, php-fpm forks to the background and returns
  # immediately -- this script (bash, the container's PID 1) would then hit
  # its own end and exit, tearing down the whole container and killing the
  # now-orphaned php-fpm child before it ever served anything. Confirmed
  # live: the container ran cleanly through run_updates() and then just
  # stopped, no php-fpm startup output at all.
  # exec: replaces this script as PID 1 with php-fpm directly, so
  # `docker stop`'s SIGTERM reaches php-fpm for a clean shutdown instead of
  # going to bash first.
  exec php-fpm --nodaemonize
}

main
