# dockerbuilds

## Directory Structure

  - bin                - handy scripts for repo management
  - images             - self contained image directories, consisting of scripts, configuration and Dockerfiles
  - example            - example docker-compose stacks
  - docker-compose.yml - contains build parameters for building images locally (such as build context)

## Manual Local Image Build (built on local machine)

You might want to test that images will rebuild, before pushing tags or master changes and waiting for Dockerhub automated builds.

... Or maybe the automated Dockerhub builds are failing.

### Build

To build manually, use the docker-compose.yml file (which has the build details) as follows.

```
docker-compose build ${image}
```

Where ${image} is the name of the image to build, omit this variable to build all images locally. You can also specify more than one ${image} at once.

You can build all the images locally at once, by simply running:

```
docker-compose build
```

All images will be built with the encircle repository and latest tag (encircle/${image}:latest).

### Tag

As the images are built as the 'latest' tag now we need to tag the images to the version we want.

For example:

```
image=wordpress
version=v1.4.6
docker tag encircle/${image}:latest encircle/${image}:${version}
```

This will result in a tag of ${version} that is exactly the same as the 'latest' image.

### Push to Dockerhub

Finally you can push the image to Dockerhub, as follows:

Push the latest image:

```
docker push encircle/${image}:latest
```

Push the tagged image:

```
docker push enicrcle/${image}:${version}
```

Unfortunately you can only push the images one at a time.

## Quick Automated Remote Rebuild

Images need to be rebuilt when vulnerabilities are discovered.

Technically no changes are actually required to the Dockerfiles, but the packages are upgraded as part of the build process.

The quick way to do this is to just update the changelog and push to github which will trigger Dockerhub to rebuild them.

The 'rebuild' script will do this for you.

The script will:

1. Determine the current version from the changelog
2. Increment the current version to the next minor version
3. Update the changelog
4. Commit, tag and push to master along with new tag
5. Dockerhub will then be triggered to rebuild the latest tag, and build the new minor version tag

To run the script, execute as follows:

```
cd bin && ./rebuild
```

You will need to enter Github credentials, if you don't use SSH otherwise your private key password.

## Manual Remote Image Rebuild

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

## Vulnerability Scanning

Vulnerability scanning is enabled for all images on Dockerhub.

This means that whenever an image is rebuilt, Dockerhub scans the image using Synk and reports any vulnerabilities present.

Do not use any images that contain serious vulnerabilities.

## Build Caching

Docker and Dockerhub provides build caching, which will read from the cache if a Dockerfile doesn't change.

As package upgrades do not actuall modify the Dockerfile, build caching is disabled on Dockerhub automatic builds to ensure packages are upgraded.

## Example Usage

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

    ##### Wordpress
    ```
    docker-compose -f docker-compose-wp.yml up -d
    ```
    ##### Drupal
    ```
    docker-compose -f docker-compose-dr.yml up -d
    ```

3. Check status of stack components

    ```
    docker-compose ps
    ```

## Postfix

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

## Migration

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

    ##### Wordpress
    ```
    docker-compose -f docker-compose-wp.yml up -d
    ```
    ##### Drupal
    ```
    docker-compose -f docker-compose-dr.yml up -d
    ```
