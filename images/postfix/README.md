# Postfix

This readme is for the encircle Postfix image.

The image is Postfix configured on Alpine Linux, packaged with sendgrid integration if required.

This image uses supervisord to run several processes within the same container. In this case, those processes are postfix and DKIM.

## Environment Variables

**HOSTNAME**: Postfix myhostname hostname

**SENDGRID**: (TRUE/FALSE) Whether to use SendGrid as relay host or not

**SENDGRID_API_KEY**: API key for SendGrid (required if using SendGrid)
