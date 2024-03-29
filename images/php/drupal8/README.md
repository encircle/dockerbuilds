# Drupal 8

This readme is for the encircle Drupal 8 image.

The image is Drupal 8 on the official PHP alpine image, packaged with Drush.

Installations/upgrades are automated, if no site is present a new one will be installed.

If a site is present (through a persistent mount), the version will be checked against the image version and upgraded if required.

## Environment Variables

**SITE**: Space seperated domains, the first of which is used for sendmail From address (noreply@$domain)

**DB_HOST**: Database host for Drupal

## Upgrade Drupal Version

To upgrade the Drupal version to a later Drupal 8 release, follow the below steps:

1. Download the Drupal tar archive

```
DRUPAL_VERSION=8.19
curl -fSL "https://ftp.drupal.org/files/projects/drupal-${DRUPAL_VERSION}.tar.gz" -o drupal.tar.gz
```

2. Get the MD5 hash and make a note of it

```
md5sum drupal.tar.gz && rm drupal.tar.gz
```

3. Update the Drupal version environment variable in the Dockerfile (towards the top)

```
vi Dockerfile
```

Change:

```
ENV DRUPAL_VERSION 8.19
```

4. Update the Drupal MD5 hash in the Dockerfile

```
vi Dockerfile
```

Change:

```
ENV DRUPAL_MD5 67c8e2974421e8d549ad705169977498
```

5. Build the image locally and ensure it completes successfully

** Run this command from the repository root **

```
docker-compose build drupal8
```

6. Scan the image for vulnerabilities

** Install trivy with apt-get install trivy **

Clear cache first:

```
trivy --clear-cache
```

Then scan:

```
trivy encircle/drupal8:latest
```

7. Update the CHANGELOG

For example:

```
v1.6.0
======
- Updated Drupal version from v1.x.x to v1.x.x
```

8. Commit and push the changes (Dockerhub will build the 'latest' tag from the master branch)

```
git commit -a -m 'updated drupal from v1.x.x to v1.x.x'
git push origin master
```

9. Check Dockerhub and ensure the 'latest' build completes successfully

10. Tag and push the new build (Dockerhub will build the v1.x.x tag from this tag)

```
git tag v1.x.x
git push --tags
```

11. Check Dockerhub and ensure the tagged build completes successfully

12. Test the new tag on either a low priority instance, or by springing up a local Drupal (example docker-composes in this repo)
