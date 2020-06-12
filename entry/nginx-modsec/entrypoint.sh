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

function main() {
  set -e
  env_sub
  letsencrypt
  htpasswd
  nginx -g 'daemon off;'
}

main
