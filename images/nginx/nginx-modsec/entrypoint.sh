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
  chmod 600 /var/log/nginx/*.log
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

  envsubst '${AV_HOST},${AV_PORT},${AV_APIKEY}' < /usr/local/bin/clamd-hook.sh > /tmp/clamd-hook.sh \
    && mv /tmp/clamd-hook.sh /usr/local/bin/clamd-hook.sh \
    && chown root:nginx /usr/local/bin/clamd-hook.sh \
    && chmod 750 /usr/local/bin/clamd-hook.sh

  [[ $AV_SCAN == 'TRUE' ]] \
    && sed -i 's/SecRuleRemoveById 666666//g' /etc/nginx/modsec/modsecurity.conf \
    || (grep -qxF 'SecRuleRemoveById 666666' /etc/nginx/modsec/modsecurity.conf || echo 'SecRuleRemoveById 666666' >> /etc/nginx/modsec/modsecurity.conf)

}

function custom_errors()
{
  conf_dir=/etc/nginx/hardening.d

  # Undisable everything by default
  for conf_file in $(ls $conf_dir/*disabled); do
    mv $conf_file ${conf_file%.disabled}.conf
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

  ipv4=$(curl -s https://www.cloudflare.com/ips-v4)
  ipv6=$(curl -s https://www.cloudflare.com/ips-v6)

  echo '# Cloudflare IP addresses' > $conf_file

  for ip in $ipv4; do
    echo "set_real_ip_from $ip;" >> $conf_file
  done

  echo ''

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
  get_cloudflare_ips
  nginx -g 'daemon off;'
}

main
