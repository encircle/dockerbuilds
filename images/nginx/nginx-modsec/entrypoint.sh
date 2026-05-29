#!/bin/bash

function env_sub()
{
  envsubst '${SITE},${WEBROOT},${FPM_HOST},${ENDPOINT}' < /etc/nginx/conf.d/default.conf > /tmp/default.conf && mv /tmp/default.conf /etc/nginx/conf.d/default.conf
}

function htpasswd()
{
  echo "$HTPASS" > /etc/nginx/.htpasswd
}

function log_permissions()
{
  touch /var/log/nginx/access.log
  touch /var/log/nginx/error.log
  touch /var/log/nginx/modsec_audit.log
  chown :10013 /var/log/nginx/*.log
  chmod 640 /var/log/nginx/*.log
}

function basic_auth_whitelist()
{
  whitelist_file=/etc/nginx/conf.d/ip-whitelist.conf.include
  echo '' > $whitelist_file
  for ip in $(env | grep IP_WHITELIST | awk -F '=' '{print $2}'); do
    echo "allow $ip;" >> $whitelist_file
  done
}

function modsec()
{
  envsubst '${MODSEC_ENGINE_MODE}' < /etc/nginx/modsec/modsecurity.conf > /tmp/modsecurity.conf \
    && mv /tmp/modsecurity.conf /etc/nginx/modsec/modsecurity.conf
}

function custom_errors()
{
  conf_dir=/etc/nginx/hardening.d

  # Undisable everything by default
  for conf_file in "$conf_dir"/*.disabled; do
    [ -e "$conf_file" ] || continue
    mv "$conf_file" "${conf_file%.disabled}.conf"
  done

  # Disable file1.conf file2.conf file3.conf in $DISABLE_CONF variable
  files=$(env | grep DISABLE_CONF | awk -F '=' '{print $2}')
  for conf_file in ${files//,/}; do
    conf_file=${conf_dir}/${conf_file%.conf}
    mv ${conf_file}.conf ${conf_file}.disabled
  done
}

function get_cloudflare_ips() {
  conf_file=/etc/nginx/conf.d/cloudflare.conf

  ipv4=$(curl -sf --max-time 10 https://www.cloudflare.com/ips-v4 || true)
  ipv6=$(curl -sf --max-time 10 https://www.cloudflare.com/ips-v6 || true)

  if [ -z "$ipv4" ]; then
    echo "WARNING: Failed to fetch Cloudflare IPv4 addresses, skipping cloudflare.conf"
    return
  fi

  echo '# Cloudflare IP addresses' > $conf_file

  for ip in $ipv4; do
    echo "set_real_ip_from $ip;" >> $conf_file
  done

  echo '' >> $conf_file

  for ip in $ipv6; do
    echo "set_real_ip_from $ip;" >> $conf_file
  done

  echo '' >> $conf_file

  echo "real_ip_header CF-Connecting-IP;" >> $conf_file
}

function setup_cache() {
  server_include=/etc/nginx/conf.d/cache-server.conf.include
  location_include=/etc/nginx/conf.d/cache-location.conf.include

  if [ "${NGINX_CACHE_ENABLED:-false}" = "true" ]; then
    cat > $server_include << 'EOF'
set $skip_cache 0;

if ($request_method = POST) { set $skip_cache 1; }
if ($query_string != "")    { set $skip_cache 1; }

# WordPress, Drupal, CiviCRM admin/dynamic paths
if ($request_uri ~* "/wp-admin/|/wp-login.php|/xmlrpc.php|wp-cron.php|/admin/|/user/login|/user/register|/cron.php|/install.php|/update.php|/civicrm/") {
    set $skip_cache 1;
}

# WordPress session cookies — anchored to cookie name to avoid matching inside cookie values
if ($http_cookie ~* "(^|;\s*)wordpress_logged_in") { set $skip_cache 1; }
if ($http_cookie ~* "(^|;\s*)wordpress_[a-f0-9]{32}") { set $skip_cache 1; }
if ($http_cookie ~* "(^|;\s*)wp-postpass") { set $skip_cache 1; }
if ($http_cookie ~* "(^|;\s*)comment_author") { set $skip_cache 1; }

# Drupal session cookies — anchored to cookie name
if ($http_cookie ~* "(^|;\s*)SESS[a-z0-9]+") { set $skip_cache 1; }
if ($http_cookie ~* "(^|;\s*)SSESS[a-z0-9]+") { set $skip_cache 1; }
EOF
    cat > $location_include << 'EOF'
fastcgi_cache_bypass $skip_cache;
fastcgi_no_cache     $skip_cache;
add_header X-FastCGI-Cache $upstream_cache_status always;
EOF
  else
    echo 'fastcgi_cache off;' > $server_include
    truncate -s 0 $location_include
  fi
}

function main() {
  set -e
  env_sub
  htpasswd
  log_permissions
  basic_auth_whitelist
  modsec
  custom_errors
  setup_cache
  no_cloudflare=${NO_CLOUDFLARE:-False}
  if [ $no_cloudflare = False ]; then
    get_cloudflare_ips
  fi
  nginx -g 'daemon off;'
}

main
