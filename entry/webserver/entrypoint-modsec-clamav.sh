function start_nginx() {
  nginx -g 'daemon off;' &
}

function install_packages() {
  apk add netcat-openbsd bc curl wget git bash openssl libressl;
}

function install_client()
{
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
    --cert-file /etc/nginx/certs/site.crt \
    --key-file /etc/nginx/certs/site.key \
    --fullchain-file /etc/nginx/certs/fullchain.crt \
    --debug 
}

function letsencrypt()
{
  if [[ "$LETSENCRYPT" == "YES" ]]; then
    rm -rf /var/www/.well-known
    start_nginx
    install_packages
    install_client
    setup
    get_cert
    nginx -s stop
  fi
}

function clamav() {
  freshclam -d &
  clamd &
}

function main() {
  set -e
  letsencrypt
  clamav
  nginx -g 'daemon off;'
}

main
