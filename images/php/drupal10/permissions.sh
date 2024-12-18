# Set hardened permissions
# /
chown root:www-data /var/www/html/site/web/
chmod 750 /var/www/html/site/web/
find /var/www/html/site/web/ -maxdepth 1 -type f -exec chown root:www-data {} +
find /var/www/html/site/web/ -maxdepth 1 -type f ! -perm 0740 -exec chmod 740 {} +

# Generic
find /var/www/html/site/web/ -exec chown root:www-data {} +
find /var/www/html/site/web/ -type d ! -perm 0750 -exec chmod 750 {} +
find /var/www/html/site/web/ -type f ! -perm 0640 -exec chmod 640 {} +

# Git
find /var/www/html/site/web/.git -exec chown root:root {} +
find /var/www/html/site/web/.git -type d ! -perm 0750 -exec chmod 750 {} +
find /var/www/html/site/web/.git -type f ! -perm 0640 -exec chmod 640 {} +

# /sites/default/files
find /var/www/html/site/web/sites/default/files -type d ! -perm 0770 -exec chmod 770 {} +
find /var/www/html/site/web/sites/default/files -type f ! -perm 0660 -exec chmod 660 {} +
