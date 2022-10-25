# Wordpress

This readme is for the encircle Wordpress image.

The image is Wordpress on the official PHP alpine image, packaged with wp-cli.

Installations/upgrades are automated, if no site is present a new one will be installed.

If a site is present (through a persistent mount), the version will be checked against the image version and upgraded if required.

## Environment Variables

**SITE**: Space seperated domains, the first of which is used for sendmail From address (noreply@$domain)

**WORDPRESS_DB_HOST**: Database hostname

**WORDPRESS_DB_NAME**: Database name

**WORDPRESS_DB_USER**: Database user

## Upgrade Wordpress Version

To upgrade the Wordpress version to a later release, follow the below steps:

1. Update the Wordpress version environment variable in the Dockerfile (towards the top)

```
vi Dockerfile
```

Change:

```
ENV WORDPRESS_VERSION 5.7.1
```

2. Build the image locally and ensure it completes successfully

** Run this command from the repository root **

```
docker-compose build wordpress
```

3. Scan the image for vulnerabilities

** Install trivy with apt-get install trivy **

Clear cache first:

```
trivy --clear-cache
```

Then scan:

```
trivy encircle/wordpress:latest
```

7. Update the CHANGELOG

For example:

```
v1.6.0
======
- Updated Wordpress version from v1.x.x to v1.x.x
```

4. Commit and push the changes (Dockerhub will build the 'latest' tag from the master branch)

```
git commit -a -m 'updated wordpress from v1.x.x to v1.x.x'
git push origin master
```

5. Check Dockerhub and ensure the 'latest' build completes successfully

6. Tag and push the new build (Dockerhub will build the v1.x.x tag from this tag)

```
git tag v1.x.x
git push --tags
```

7. Check Dockerhub and ensure the tagged build completes successfully

8. Test the new tag on either a low priority instance, or by springing up a local Wordpress (example docker-composes in this repo)
