# NGINX Modsec

This readme is for the encircle nginx-modsec image.

The image is NGINX on Alpine packaged with modsecurity and the OWASP ruleset.

The default configuration is configured for PHP FPM applications.

During the build process, Modsecurity module and connector are compiled in a throwaway image. 

The compiled Modsecurity module and connector are then copied over to the resulting image.

## Volume Mounts

The following directories are useful to mount over (or mount files into):

```
webroot       /var/www/html
hardening     /etc/nginx/hardening.d
general conf  /etc/nginx/conf.d
certificates  /etc/nginx/certs
```

## Environment Variables

**SITE**: Space seperated list of domain names for site\

**ENV**: Basic auth enabled if not PROD\

**IP_WHITELIST_***: IP addresses exempt from basic authentication. As many as needed.\

**FPM_HOST**: FPM host for proxied requests\

**HTPASS**: .htpasswd format credentials (user:hash). This is the HASHED password, not plaintext.\

**MODSEC_ENGINE_MODE**: (On/Off/DetectionOnly) Mode for modsec engine, check the docs\

**DISABLE_CONF**: Disable hardening config files. e.g.   DISABLE_CONF=custom_error.conf block_files.conf\

**AV_SCAN**: (TRUE/FALSE) Whether to scan file uploads via webserver\

**AV_HOST**: Host on which restingclam is hosted\

**AV_PORT**: Port on which restingclam is listening

**NO_CLOUDFLARE**: If set to True the container won't download cloudflare public ips and autogenerate Nginx's set_real_ip directives in /etc/nginx/conf.d/cloudflare.conf. This allows a container to override the stock Cloudflare real_ip configuration For use when the container is used behind a Proxy server

**DRUPAL_MODE**: If set to on - clean urls add the original path as the q parameter in the url for index.php rewriting

## Upgrade NGINX Version

Update the NGINX_VERSION environment variable in the Dockerfile

```
vi Dockerfile
```

Change:

```
ENV NGINX_VERSION 1.19.0
```

## Uprade the Modsec Version

Update the MODSEC_VERSION environment variable in the Dockerfile

```
vi Dockerfile
```

Change:

```
ARG MODSEC_VERSION=3
```

## Upgrade the OWASP CRS Version

Update the MODSEC_VERSION environment variable in the Dockerfile

```
vi Dockerfile
```

Change:

```
ARG OWASP_CRS_VERSION=3.3.4
```

## Modsec

To whitelist specific rules for modsec, mount a modsec whitelist directory as follows:

```
- ./modsec:/etc/nginx/modsec/whitelist
```

Add a whitelist.conf file in the modsec directory

```
touch modsec/whitelist.conf
```

And add any whitelisting rules to the file

## Letsencrypt

Use the letsencrypt script to add and renew letsencrypt certificates.

Make sure to update the variables within the script to match domains and containers etc.

Variables:

  - domain - Domain for which certificate is required
  - webserver_container - Name of the webserver container for the site
  - containerdir - Directory for the stack
  - email - Email for letsencrypt notifications

##### Initial certificate

```
letsencrypt.sh init test
```

The test option hits letsencrypt staging API, remove this for Production use.

##### Renewals

```
letsencrypt.sh renew
```
