#!/bin/sh

function env_sub()
{
  envsubst '${DB_NAME},${DB_USER},${USER_PASS},${TABLE_PREFIX}' < /var/www/html/sites/default/settings.template > /var/www/html/sites/default/settings.php
}

function main()
{
  env_sub
  php-fpm
}

main
