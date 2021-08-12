# NGINX Proxy

This readme is for the encircle nginx-proxy image.

The image uses encircle/nginx-modsec:latest as the base image and simply replaces the default.conf with
a new version for proxying (the standard nginx-modsec is a PHP FPM enabled site).

## Environment Variables

All those available with NGINX modsec and...

**ENDPOINT**: Proxy endpoint (e.g. myapp.example.com:4444)
