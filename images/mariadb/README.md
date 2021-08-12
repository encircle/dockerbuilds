# MariaDB

This readme is for the encircle nginx-proxy image.

The image is the official MariaDB image (ubuntu) from dockerhub with some simple additions.

There is no official Alpine Linux image.

## Environment Variables

**MYSQL_ROOT_PASS**: Desired MySQL root password

**MYSQL_DATABASE**: Desired MySQL database name

**MYSQL_USER**: Desired MySQL database user

**MYSQL_PASSWORD**: Desired MySQL database user password

## Upgrade MariaDB Version

Although package updates are done as part of the build process, this will not update the MariaDB version as these
are held.

To upgrade the MariaDB version, change base image. For example:

Change:

```
FROM mariadb:10.5.3
```

To:

```
FROM mariadb:10.5.4
```
