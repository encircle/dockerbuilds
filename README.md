# dockerbuilds

## Contributing ##

### Directory Structure ###

  - bin                - handy scripts for repo management and more
  - conf               - configuration used by images
  - entry              - entrypoint scripts for images
  - scripts            - scripts used by images
  - images             - the actual Dockerfiles
  - example            - example docker-compose stacks
  - docker-compose.yml - docker-compose for building image locally

### Local Image Rebuild ###

You might want to test that images will rebuild, before pushing tags or master changes and waiting for Dockerhub automated builds.

To build manually, use the docker-compose.yml file as follows.

```
docker-compose build ${image}
```

Where ${image} is the name of the image to build, omit this variable to build all images locally.

All images will be built with the encircle repository and latest tag (encircle/theimage:latest).

### Quick Remote Image Rebuild ###

Images need to be rebuilt when vulnerabilities are discovered, the rebuild script does this automatically.

The script will:

1. Determine the current version
2. Increment the current version to the next minor version
3. Update the CHANGELOG
4. Commit, tag and push to master along with new tag
5. Dockerhub will then automatically rebuild the latest tag, and build the new minor version tag

To run the script, execute as follows:

```
cd bin && ./rebuild
```

You will need to enter Github credentials, if you don't use SSH otherwise your private key password.

### Manual Remote Image Rebuild ###

For changes over and above package vulnerabilities, i.e. any code changes.

1. Make the changes
2. Update the CHANGELOG, incrementing version as required
3. Commit the changes

    ```
    git commit -a -m 'changes'
    ```

4. Tag the build

    ```
    git tag v1.2.3
    ```

5. Push tags

    ```
    git push --tags
    ```

6. Push master

    ```
    git push origin master
    ```

## Environment Variables ##

These are the environment variables used across the stack. In the example docker-compose files, variables are set in .env, and then environment variables are mapped in the docker-compose files to the variables set in .env. This is so that we can have a single variable set in .env and reference multiple times in docker-compose (e.g. using a single variable from .env to set the environment variables for database name in both MySQL and Wordpress containers).

### NGINX Modsec ###

**SITE**: Space seperated list of domain names for site. First domain used as PHP sendmail From address\

**ENV**: Basic auth enabled if not PROD\

**IP_WHITELIST_***: IP addresses exempt from basic authentication. As many as needed.\

**FPM_HOST**: FPM host for proxied requests\

**HTPASS**: .htpasswd format credentials (user:hash). This is the HASHED password, not plaintext.\

**MODSEC_ENGINE_MODE**: (On/Off/DetectionOnly) Mode for modsec engine, check the docs\

**DISABLE_CONF**: Disable hardening config files. e.g.   DISABLE_CONF=custom_error.conf block_files.conf\

**AV_SCAN**: (TRUE/FALSE) Whether to scan file uploads via webserver\

**AV_HOST**: Host on which restingclam is hosted\

**AV_PORT**: Port on which restingclam is listening


### NGINX Proxy ###

All those available with NGINX modsec and...

**ENDPOINT**: Proxy endpoint (e.g. myapp.example.com:4444)


### MariaDB ###

**MYSQL_ROOT_PASS**: Desired MySQL root password

**MYSQL_DATABASE**: Desired MySQL database name

**MYSQL_USER**: Desired MySQL database user

**MYSQL_PASSWORD**: Desired MySQL database user password


### Wordpress ###

**SITE**: Domain, used for sendmail From address (see NGINX variables)

**WORDPRESS_DB_HOST**: Database hostname

**WORDPRESS_DB_NAME**: Database name

**WORDPRESS_DB_USER**: Database user


### Drupal ###

**SITE**: Domain, used for sendmail From address (see NGINX variables)

**DB_HOST**: Database host for Drupal


### Postfix ###

**HOSTNAME**: Postfix myhostname hostname

**SENDGRID**: (TRUE/FALSE) Whether to use SendGrid as relay host or not

**SENDGRID_API_KEY**: API key for SendGrid (required if using SendGrid)

## Usage ##

1. Set environment variables in .env file

    ```
    echo 'SITE=www.example.com' > .env
    echo 'ENV=PROD' >> .env
    echo 'IP_WHITELIST_1=37.128.134.212' >> .env
    echo 'IP_WHITELIST_2=5.153.250.222' >> .env
    echo 'FPM_HOST=wordpress|drupal' >> .env
    echo 'ROOT_PASS=password' >> .env
    echo 'DB_NAME=wp_db' >> .env
    echo 'DB_USER=wp_usr' >> .env
    echo 'USER_PASS=password' >> .env
    echo 'TABLE_PREFIX=wp_' >> .env
    echo "HTPASS=USER:$(openssl passwd -apr1 PASSWORD)" >> .env
    echo 'MODSEC_ENGINE_MODE=On' >> .env
    echo 'DISABLE_CONF=' >> .env
    echo 'AV_HOST=localhost' >> .env
    echo 'AV_PORT=10101' >> .env
    ```

2. Run the stack

    ##### Wordpress #####
    ```
    docker-compose -f docker-compose-wp.yml up -d
    ```
    ##### Drupal #####
    ```
    docker-compose -f docker-compose-dr.yml up -d
    ```

3. Check status of stack components

    ```
    docker ps -a
    ```

## Postfix ##

Postfix is used as the MTA for the containers, to use postfix with the PHP container:

1. Start the postfix service

    ```
    docker-compose -f docker-compose-pf.yml up -d
    ```

2. Uncomment the network configuration in the stack compose file

   ```
   sed -i 's/#//g' docker-compose-wp.yml
   sed -i 's/#//g' docker-compose-dr.yml
   ```

3. Start or restart the stack

   ```
   docker-compose -f docker-compose-wp.yml up -d
   docker-compose -f docker-compose-dr.yml up -d
   ```

## Migration ##

To migrate an existing site:

1. Create tar archive of site

    ##### Wordpress #####
    ```
    cd /path/to/wordpress && tar -cvzf /tmp/wordpress.tar.gz *
    ```
    ##### Drupal #####
    ```
    cd /path/to/drupal && tar -cvzf /tmp/drupal.tar.gz *
    ```

2. Dump site database

    ```
    mysqldump --defaults-file=/etc/mysql/debian.cnf db_name > /tmp/dump.sql
    ```

3. Copy site archive and MySQL dump to the docker server

4. Create a directory named 'migrations' in the same directory as the docker-compose.yml and move the SQL dump into this folder

    ```
    mkdir migrations && mv /tmp/dump.sql migrations/ && chown -R 999:999 migrations
    ```

5. Create a directory for the site files and decompress the site archive into this directory

    ##### Wordpress #####
    ```
    mkdir wordpress && tar -xvzf /tmp/wordpress.tar.gz -C wordpress
    ```
    ##### Drupal #####
    ```
    mkdir drupal && tar -xvzf /tmp/drupal.tar.gz -C drupal
    ```

6. Set environment variables in .env file

    **Note, DB_NAME, DB_USER, USER_PASS and TABLE_PREFIX must match existing site**

    ```
    echo 'SITE=www.example.com' > .env
    echo 'ENV=PROD' >> .env
    echo 'IP_WHITELIST_1=37.128.134.212' >> .env
    echo 'IP_WHITELIST_2=5.153.250.222' >> .env
    echo 'FPM_HOST=wordpress|drupal' >> .env
    echo 'ROOT_PASS=password' >> .env
    echo 'DB_NAME=wp_db' >> .env
    echo 'DB_USER=wp_usr' >> .env
    echo 'USER_PASS=password' >> .env
    echo 'TABLE_PREFIX=wp_' >> .env
    echo "HTPASS=USER:$(openssl passwd -apr1 PASSWORD)" >> .env
    echo 'MODSEC_ENGINE_MODE=On' >> .env
    echo 'DISABLE_CONF=' >> .env
    echo 'AV_HOST=localhost' >> .env
    echo 'AV_PORT=10101' >> .env
    ```

7. Run the stack

    ##### Wordpress #####
    ```
    docker-compose -f docker-compose-wp.yml up -d
    ```
    ##### Drupal #####
    ```
    docker-compose -f docker-compose-dr.yml up -d
    ```

## Modsec ##

To whitelist specific rules for modsec, mount a modsec whitelist directory as follows:

```
- ./modsec:/etc/nginx/modsec/whitelist
```

Add a whitelist.conf file in the modsec directory

```
touch modsec/whitelist.conf
```

And add any whitelisting rules to the file

## Letsencrypt ##

Use the letsencrypt script to add and renew letsencrypt certificates.

Make sure to update the variables within the script to match domains and containers etc.

Variables:

  - domain - Domain for which certificate is required
  - webserver_container - Name of the webserver container for the site
  - containerdir - Directory for the stack
  - email - Email for letsencrypt notifications

##### Initial certificate #####

```
letsencrypt.sh init test
```

The test option hits letsencrypt staging API, remove this for Production use.

##### Renewals #####

```
letsencrypt.sh renew
```
