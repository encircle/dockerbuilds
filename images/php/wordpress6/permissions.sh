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
find /var/www/html/.git -exec chown root:root {} +
find /var/www/html/.git ! -perm 0750 -type d -exec chmod 750 {} +
find /var/www/html/.git ! -perm 0640 -type f -exec chmod 640 {} +

# /wp-content/uploads
find /var/www/html/wp-content/uploads ! -perm 0770 -type d -exec chmod 770 {} +
find /var/www/html/wp-content/uploads ! -perm 0660 -type f -exec chmod 660 {} +
find /var/www/html/wp-content/wflogs ! -perm 0770 -type d -exec chmod 770 {} +
find /var/www/html/wp-content/wflogs ! -perm 0660 -type f -exec chmod 660 {} +


# /wp-config.php
chmod 440 /var/www/html/wp-config.php
