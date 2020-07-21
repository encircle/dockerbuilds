#!/bin/sh

# Essentially, if the Drupal version within the volume differs from the Drupal version
# environment variable within the image, then we will download the new code base and 
# decompress. This brings the Drupal volume in line with the image version.

set -x

volume_version=$(drush status | grep 'Drupal version' | awk '{print $4}')
image_version=$DRUPAL_VERSION

if [[ $volume_version != $image_version ]]; then

  echo "Updating Drupal from $installed_version to $image_version"

  # Download process from Drupal official image
  set -eux; \
    curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz; \
    echo "${DRUPAL_MD5} *drupal.tar.gz" | md5sum -c -; \
    tar -xz --strip-components=1 -f drupal.tar.gz; \
    rm drupal.tar.gz; \
    chown -R www-data:www-data sites modules themes

fi 

# Start FPM
php-fpm
