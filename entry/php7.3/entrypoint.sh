#!/bin/sh

echo 'Installing PHP extensions'
IFS=","
for ext in $PHP_EXT
do
  echo $ext
  docker-php-ext-install $ext
done

echo 'Starting PHP...'
php-fpm
