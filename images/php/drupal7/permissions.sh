# Set hardened permissions
# /
chown root:www-data /var/www/html/
chmod 750 /var/www/html/
find /var/www/html/ -maxdepth 1 -type f -exec chown root:www-data {} +
find /var/www/html/ -maxdepth 1 -type f ! -perm 0740 -exec chmod 740 {} +

# Generic
find /var/www/html/ -exec chown root:www-data {} +
find /var/www/html/ -type d ! -perm 0750 -exec chmod 750 {} +
find /var/www/html/ -type f ! -perm 0640 -exec chmod 640 {} +

# Git
find /var/www/html/.git -exec chown root:root {} +
find /var/www/html/.git -type d ! -perm 0750 -exec chmod 750 {} +
find /var/www/html/.git -type f ! -perm 0640 -exec chmod 640 {} +

# /sites/default/files
find /var/www/html/sites/default/files -type d ! -perm 0770 -exec chmod 770 {} +
find /var/www/html/sites/default/files -type f ! -perm 0660 -exec chmod 660 {} +