# Redmine

This readme is for the encircle Redmine image.

The image is the official Redmine Alpine Linux image from dockerhub, with some basic adjustments.

## Environment Variables

**REDMINE_DB_MYSQL**: The database hostname

**REDMINE_DB_DATABASE**: The database name

**REDMINE_DB_USERNAME**: The database username

**REDMINE_DB_PASSWORD**: The database password

**REDMINE_SECRET_KEY_BASE**: The Redmine secret key

## Upgrade Redmine Version

To upgrade the Redmine version, change base image. For example:

Change:

```
FROM redmine:4.1.1-alpine
```

To:

```
FROM redmine:4.2.1-alpine
```
