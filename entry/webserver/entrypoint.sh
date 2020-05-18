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

function request_cert()
{
  cd /root/.acme.sh
  ./acme.sh --issue -w /var/www/html -d $SITE -k 4096 --debug
}

function install_cert()
{
  cd /root/.acme.sh
  ./acme.sh --installcert -d $SITE \
    --keypath /etc/nginx/ssl/letsencrypt/$SITE/$SITE.key \
    --fullchainpath /etc/nginx/ssl/letsencrypt/$SITE/$SITE.cer \
    --reloadcmd '/etc/init.d/nginx restart'
}

main()
{
  install_client
  setup
  request_cert
  install_cert
}

main
