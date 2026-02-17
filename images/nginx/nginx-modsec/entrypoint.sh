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

function main() {
  set -e
  env_sub
  htpasswd
  log_permissions
  basic_auth_whitelist
  modsec
  custom_errors
  no_cloudflare=${NO_CLOUDFLARE:-False}
  if [ $no_cloudflare = False ]; then
    get_cloudflare_ips
  fi
  nginx -g 'daemon off;'
}

main
