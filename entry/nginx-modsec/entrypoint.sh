function start_nginx() {
  nginx -g 'daemon off;' &
}

function install_packages() {
  apk add netcat-openbsd bc curl wget git bash openssl libressl;
}

function install_client()
{
  rm -rf /tmp/acme.sh
  cd /tmp && git clone https://github.com/Neilpang/acme.sh.git
  cd acme.sh && ./acme.sh --install
}

function setup()
{
  mkdir -p /var/www/html/.well-known/acme-challenge
  chown -R 101:82 /var/www/html/.well-known/acme-challenge
  chmod -R 0555 /var/www/html/.well-known/acme-challenge

  mkdir -p /etc/nginx/ssl/letsencrypt/$SITE
  openssl dhparam -dsaparam -out /etc/nginx/ssl/letsencrypt/$SITE/dhparams.pem 4096
}

function get_cert()
{
  cd /root/.acme.sh
  ./acme.sh --issue -w /var/www/html -d $SITE \
    --keylength 4096 \
    --cert-file /etc/nginx/certs/domain.crt \
    --key-file /etc/nginx/certs/site.key \
    --fullchain-file /etc/nginx/certs/site.crt \
    --debug 
}

function env_sub()
{
  envsubst '${SITE},${FPM_HOST}' < /etc/nginx/conf.d/default.conf > /tmp/default.conf && mv /tmp/default.conf /etc/nginx/conf.d/default.conf
}

function letsencrypt()
{
  if [[ "$LETSENCRYPT" == "YES" ]]; then
    if [[ ! -f /tmp/.gotcert ]]; then
      rm -rf /var/www/.well-known
      start_nginx
      install_packages
      install_client
      setup
      get_cert
      nginx -s stop
      touch /tmp/.gotcert
    fi
  fi
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

  envsubst '${AV_HOST},${AV_PORT}' < /usr/local/bin/clamd-hook.sh > /tmp/clamd-hook.sh \
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

function main() {
  set -e
  env_sub
  letsencrypt
  htpasswd
  log_permissions
  basic_auth_whitelist
  modsec
  custom_errors
  nginx -g 'daemon off;'
}

main
