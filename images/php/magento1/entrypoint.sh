set -x

function configure_postfix() {

  DOMAIN=$(echo ${SITE} | awk -F ' ' '{ print $1 }')
  sed -i "s/\${SITE}/${DOMAIN}/g" /etc/php5/fpm/conf.d/php/conf.d/postfix.ini

}

function main() {

  configure_postfix

  # wait for the database connection
  db_status=1
  echo 'Waiting for DB to be available'
  while [[ $db_status != 0 ]]; do
    $(nc -z "$DB_HOST" 3306 > /dev/null 2>&1)
    db_status=$?
    sleep 3
  done

  # start the daemon
  /usr/sbin/php-fpm5.6 -O
  /bin/bash -c "trap : TERM INT; sleep infinity & wait"
}

main
