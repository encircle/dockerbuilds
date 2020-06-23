# dockerbuilds

## Environment Variables ##

These are the environment variables used across the stack.

**SITE** -> Site hostname (www.example.com)

**LETSENCRYPT** -> YES/NO -> Install LetsEncrypt certificate with automatic renewals
- (DNS must be configured and firewalls open for LetsEncrypt verification)

**ENV** -> If not prod, basic auth will be required

**FPM_HOST** -> Docker network hostname for FPM host (e.g. wordpress)

**ROOT_PASS** -> Desired MySQL root password

**DB_NAME** -> Desired (or existing) MySQL database name

**DB_USER** -> Desired (or existing) MySQL Wordpress user

**USER_PASS** -> Desired (or existing) MySQL user password

**TABLE_PREFIX** -> Desired (or existing) database table prefix

**HTPASS** -> .htpasswd format credentials (user:hash)

## Usage ##

1. Set environment variables in .env file

    ```
    echo 'SITE=www.example.com' > .env
    echo 'LETSENCRYPT=YES' >> .env
    echo 'ENV=PROD' >> .env
    echo 'FPM_HOST=wordpress|drupal' >> .env
    echo 'ROOT_PASS=password' >> .env
    echo 'DB_NAME=wp_db' >> .env
    echo 'DB_USER=wp_usr' >> .env
    echo 'USER_PASS=password' >> .env
    echo 'TABLE_PREFIX=wp_' >> .env
    echo "HTPASS=USER:$(openssl passwd -apr1 PASSWORD)" >> .env
    ```

2. Run the stack

    ##### Wordpress #####
    ```
    docker-compose -f docker-compose-wp.yml up -d
    ```
    ##### Drupal #####
    ```console
    docker-compose -f docker-compose-dr.yml up -d
    ```

3. Check status of stack components

    ```
    docker ps -a
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
    echo 'LETSENCRYPT=YES' >> .env
    echo 'ENV=PROD' >> .env
    echo 'FPM_HOST=wordpress|drupal' >> .env
    echo 'ROOT_PASS=password' >> .env
    echo 'DB_NAME=wp_db' >> .env
    echo 'DB_USER=wp_usr' >> .env
    echo 'USER_PASS=password' >> .env
    echo 'TABLE_PREFIX=wp_' >> .env
    echo "HTPASS=USER:$(openssl passwd -apr1 PASSWORD)" >> .env
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
