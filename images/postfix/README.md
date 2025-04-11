# Postfix

This readme is for the encircle Postfix image.

The image is Postfix configured on Alpine Linux, packaged with sendgrid integration if required.

This image uses supervisord to run several processes within the same container. In this case, those processes are postfix and DKIM.

For opendkim, generate the keys on the host and then map those keys onto the container in a volume, e.g. - /etc/opendkim/keys:/etc/opendkim/keys, the prescence of this mapping will get the container to load opendkim, you must also pass in the dkim specific env vars

NOTE: The mounted dkim keys folder on the host must be owned by the opendkim user from the containers perspective, you can exec into the container the first time and set chown opendkim:opendkim /etc/opendkim/keys which will then show the permissions as the respective uids on the host when exiting the container, subsequent restarts will then work as expected loading the dkim keys.

## Environment Variables

**HOSTNAME**: Postfix myhostname hostname

**SENDGRID**: (TRUE/FALSE) Whether to use SendGrid as relay host or not

**SENDGRID_API_KEY**: API key for SendGrid (required if using SendGrid)

**SES**: (TRUE/FALSE) Whether to use SES as relay host or not

**SES_API_KEY**: API key for SES SMTP

**SES_API_SECRET**: API key password for SES SMTP

## DKIM

**DKIM_DOMAIN**: The domain for DKIM

**DKIM_SELECTOR**: The DKIM selector