# NGINX Modsec

This readme is for the encircle nginx-modsec image.

## Upgrade NGINX Version

1. Update the NGINX_VERSION environment variable in the Dockerfile

```
vi Dockerfile
```

Change:

```
ENV NGINX_VERSION 1.19.0
```

## Uprade the Modsec Version

1. Update the MODSEC_VERSION environment variable in the Dockerfile

```
vi Dockerfile
```

Change:

```
ARG MODSEC_VERSION=3
```

## Upgrade the OWASP CRS Version

1. Update the MODSEC_VERSION environment variable in the Dockerfile

```
vi Dockerfile
```

Change:

```
ARG OWASP_CRS_VERSION=3.3.0
```

## After upgrading

After upgrading, the new image needs to be built etc.

1. Build the image locally and ensure it completes successfully

** Run this command from the repository root **

```
docker-compose build nginx-modsec
```

2. Scan the image for vulnerabilities

** Install trivy with apt-get install trivy **

Clear cache first:

```
trivy --clear-cache
```

Then scan:

```
trivy encircle/nginx-modsec:latest
```

3. Update the CHANGELOG

For example:

```
v1.6.0
======
- Updated NGINX version from v1.x.x to v1.x.x
```

4. Commit and push the changes (Dockerhub will build the 'latest' tag from the master branch)

```
git commit -a -m 'updated nginx from v1.x.x to v1.x.x'
git push origin master
```

5. Check Dockerhub and ensure the 'latest' build completes successfully

6. Tag and push the new build (Dockerhub will build the v1.x.x tag from this tag)

```
git tag v1.x.x
git push --tags
```

7. Check Dockerhub and ensure the tagged build completes successfully

8. Test the new tag on either a low priority instance, or by springing up a local NGINX (example docker-composes in this repo)
