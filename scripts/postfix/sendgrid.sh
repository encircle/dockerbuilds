#!/bin/bash

configure_sendgrid() {
  echo 'smtp_sasl_auth_enable = yes'                             >> $main_cf
  echo 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' >> $main_cf
  echo 'smtp_sasl_security_options = noanonymous'                >> $main_cf
  echo 'smtp_sasl_tls_security_options = noanonymous'            >> $main_cf
  echo 'smtp_tls_security_level = encrypt'                       >> $main_cf
  echo 'header_size_limit = 4096000'                             >> $main_cf
  echo 'relayhost = [smtp.sendgrid.net]:587'                     >> $main_cf
  echo "[smtp.sendgrid.net]:587 apikey:$SENDGRID_API_KEY"        >> /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
}

main() {

  main_cf='/etc/postfix/main.cf'

  if [[ "${SENDGRID}" == TRUE ]]; then
    echo "Configuring Sendgrid..."
    [[ -z "${SENDGRID_API_KEY}" ]] && echo "No Sendgrid API key provided!" && exit 1
    configure_sendgrid
  else
    echo "Sendgrid not requested. Skipping."
  fi
  
}

main
