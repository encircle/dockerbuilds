# Set hardened permissions
# /
chown root:10013 /var/www/html
chmod 750 /var/www/html
find /var/www/html -maxdepth 1 -type f -exec chown root:10013 {} \;
find /var/www/html -maxdepth 1 -type f -exec chmod 740 {} \;

# /wp-admin
chown root:root /var/www/html/wp-admin
chmod 750 /var/www/html/wp-admin
find /var/www/html/wp-admin -exec chown root:www-data {} \;
find /var/www/html/wp-admin -type f -exec chmod 740 {} \;

# /wp-includes
chown root:www-data /var/www/html/wp-includes
chmod 750 /var/www/html/wp-includes
find /var/www/html/wp-includes -exec chown root:www-data {} \;
find /var/www/html/wp-includes -type f -exec chmod 740 {} \;

# /wp-content
chown root:10013 /var/www/html/wp-content
chmod 760 /var/www/html/wp-content
find /var/www/html/wp-content -exec chown root:www-data {} \;
find /var/www/html/wp-content -type f -exec chmod 760 {} \;

# /wp-content/themes
chown root:10013 /var/www/html/wp-content/themes
find /var/www/html/wp-content/themes -exec chown root:www-data {} \;
find /var/www/html/wp-content/themes -type f -exec chmod 760 {} \;

# /wp-content/plugins
find /var/www/html/wp-content/plugins -exec chown root:www-data {} \;
find /var/www/html/wp-content/plugins -type f -exec chmod 740 {} \;
