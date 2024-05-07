#!/bin/bash

configure_ses() {
  echo 'smtp_sasl_auth_enable = yes'                             >> $main_cf
  echo 'smtp_sasl_password_maps = lmdb:/etc/postfix/sasl_passwd' >> $main_cf
  echo 'smtp_sasl_security_options = noanonymous'                >> $main_cf
  echo 'smtp_sasl_tls_security_options = noanonymous'            >> $main_cf
  echo 'smtp_tls_security_level = encrypt'                       >> $main_cf
  echo 'header_size_limit = 4096000'                             >> $main_cf
  echo 'relayhost = [email-smtp.eu-west-2.amazonaws.com]:587'    >> $main_cf
  echo "[email-smtp.eu-west-2.amazonaws.com]:587 $SES_API_KEY:$SES_API_SECRET"        >> /etc/postfix/sasl_passwd
  chmod 600 /etc/postfix/sasl_passwd
  postmap /etc/postfix/sasl_passwd
}

main() {

  main_cf='/etc/postfix/main.cf'

  if [[ "${SES}" == TRUE ]]; then
    echo "Configuring SES..."
    [[ -z "${SES_API_KEY}" ]] && echo "No SES API key provided!" && exit 1
    [[ -z "${SES_API_SECRET}" ]] && echo "No SES secret key provided!" && exit 1
    configure_ses
  else
    echo "Ses not requested. Skipping."
  fi
  
}

main
