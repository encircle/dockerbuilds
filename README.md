# dockerbuilds

## Environment Variables ##

These are the environment variables used across the stack.

**SITE**  
External site hostname (www.example.com)

**LETSENCRYPT**  
YES/NO  
Install LetsEncrypt certificate with automatic renewals  
(DNS must be configured and firewalls open)

**ENV**  
DEV/TEST/UAT/PROD  
Basic auth enabled if not PROD

**IP_WHITELIST_**  
IP addresses exempt from basic auth in the format:  
IP_WHITELIST_1=192.168.0.0/24  
IP_WHITELIST_2=5.232.5.77

As many whitelist addresses can be included as required.

**FPM_HOST**  
Docker network hostname for FPM host (e.g. wordpress)

**ROOT_PASS**  
Desired MySQL root password

**DB_NAME**  
Desired (or existing) MySQL database name

**DB_USER**  
Desired (or existing) MySQL application user

**USER_PASS**  
Desired (or existing) MySQL application user password

**TABLE_PREFIX**  
Desired (or existing) database table prefix

**HTPASS**  
.htpasswd format credentials (user:hash)

**MODSEC_ENGINE_MODE**  
On/Off/DetectionOnly
Mode for modsec engine, check the docs

**DISABLE_CONF**  
Disable hardening config files
e.g. DISABLE_CONF=custom_error.conf block_files.conf

**AV_HOST**  
Host on which restingclam is hosted

**AV_PORT**
Port on which restingclam is listening

## Usage ##

1. Set environment variables in .env file

    ```
    echo 'SITE=www.example.com' > .env
    echo 'LETSENCRYPT=YES' >> .env
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
    echo 'LETSENCRYPT=YES' >> .env
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
