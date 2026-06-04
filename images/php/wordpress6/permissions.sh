#!/bin/bash
set -euo pipefail
# Set hardened permissions
# /
chown root:10013 /var/www/html
chmod 750 /var/www/html
find /var/www/html -maxdepth 1 -type f -exec chown root:www-data {} +
find /var/www/html -maxdepth 1 -type f ! -perm 0740 -exec chmod 740 {} +

# Generic
find /var/www/html -exec chown root:www-data {} +
find /var/www/html -type d ! -perm 0750 -exec chmod 750 {} +
find /var/www/html -type f ! -perm 0640 -exec chmod 640 {} +

# Git
if [[ -d /var/www/html/.git ]]; then
  find /var/www/html/.git -exec chown root:root {} +
  find /var/www/html/.git ! -perm 0750 -type d -exec chmod 750 {} +
  find /var/www/html/.git ! -perm 0640 -type f -exec chmod 640 {} +
fi

# /wp-content/uploads
if [[ -d /var/www/html/wp-content/uploads ]]; then
  find /var/www/html/wp-content/uploads ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/uploads ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/uploads/civicrm/templates_c ]]; then
  find /var/www/html/wp-content/uploads/civicrm/templates_c ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/uploads/civicrm/templates_c ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/uploads/civicrm/ext ]]; then
  find /var/www/html/wp-content/uploads/civicrm/ext ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/uploads/civicrm/ext ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/uploads/civicrm/persist/contribute ]]; then
  find /var/www/html/wp-content/uploads/civicrm/persist/contribute ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/uploads/civicrm/persist/contribute ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/uploads/civicrm/upload ]]; then
  find /var/www/html/wp-content/uploads/civicrm/upload ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/uploads/civicrm/upload ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/uploads/civicrm/custom ]]; then
  find /var/www/html/wp-content/uploads/civicrm/custom ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/uploads/civicrm/custom ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/wflogs ]]; then
  find /var/www/html/wp-content/wflogs ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/wflogs ! -perm 0660 -type f -exec chmod 660 {} +
fi
if [[ -d /var/www/html/wp-content/plugins/civicrm_extensions ]]; then
  find /var/www/html/wp-content/plugins/civicrm_extensions ! -perm 0770 -type d -exec chmod 770 {} +
  find /var/www/html/wp-content/plugins/civicrm_extensions ! -perm 0660 -type f -exec chmod 660 {} +
fi

# /wp-config.php
chmod 440 /var/www/html/wp-config.php
