# dockerbuilds

## Usage ##

1. Copy docker-compose example file

```console
cp docker-compose-example.yml docker-compose.yml
```

2. Set environment variables in .env file

 - ENV -> If not prod, basic auth will be required
 - ROOT_PASS -> Desired MySQL root password
 - DB_NAME -> Desired MySQL database name
 - DB_USER -> Desired MySQL Wordpress user
 - USER_PASS -> Desired MySQL user password
 - TABLE_PREFIX -> Desired Wordpress database table prefix

```console
echo 'ENV=PROD' > .env
echo 'ROOT_PASS=password' >> .env
echo 'DB_NAME=wp_db' >> .env
echo 'DB_USER=wp_usr' >> .env
echo 'USER_PASS=password' >> .env
echo 'TABLE_PREFIX=wp_' >> .env
```

3. Run the stack

```console
docker-compose up -d
```

4. Check status of stack components

```console
docker ps -a
```

## Migration ##

To migrate an existing Wordpress site:

1. Create tar archive of Wordpress site

```console
cd /path/to/wordpress && tar -cvzf /tmp/wordpress.tar.gz *
```

2. Dump Wordpress database

```console
mysqldump --defaults-file=/etc/mysql/debian.cnf db_name > /tmp/dump.sql
```

3. Copy Wordpress archive and MySQL dump to docker server via SFTP or similar

4. Create a directory named migrations in the same directory as the docker-compose.yml and move the SQL dump into this folder

```console
mkdir migrations && mv /tmp/dump.sql migrations/
```

5. Create a directory named wordpress and decompress the Wordpress archive into this directory

```console
mkdir wordpress && tar -xvzf /tmp/wordpress.tar.gz -C wordpress
```

6. Set environment variables in .env file

** Note, DB_NAME, DB_USER, USER_PASS and TABLE_PREFIX must match existing site **

```console
echo 'ENV=PROD' > .env
echo 'ROOT_PASS=password' >> .env
echo 'DB_NAME=wp_db' >> .env
echo 'DB_USER=wp_usr' >> .env
echo 'USER_PASS=password' >> .env
echo 'TABLE_PREFIX=wp_' >> .env
```

7. Apply standard permissions to wordpress folder and containing folders/files

```console
find wordpress -exec chown 101:82 {} \;
find wordpress -type d -exec chmod 750 {} \;
find wordpress -type f -exec chmod 640 {} \;
find wordpress -name wp-content -type d -exec chmod 750 {} \;
find wordpress -wholename *wp-content/uploads* -type d -exec chmod 770 {} \;
find wordpress -wholename *wp-content/uploads* -type f -exec chmod 660 {} \;
find wordpress -wholename *wp-content/plugins* -type d -exec chmod 770 {} \;
find wordpress -wholename *wp-content/plugins* -type f -exec chmod 660 {} \;
```

8. Run the stack

```console
docker-compose up -d
```
