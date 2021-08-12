# Memcache

This readme is for the encircle Memcache image.

The image is Memcache on Alpine Linux. Memcache is installed from the Alpine repository, whichever version is available.

This means that the latest version of Memcache available on the Alpine repository is always the installed version.

## Environment Variables

The following environment variables are available, and map to Memcache options as follows (defaults in brackets):

**MEMCACHED_USER**: --user (memcached)

**MEMCACHED_HOST**: --listen (0.0.0.0)

**MEMCACHED_PORT**: --port (11211)

**MEMCACHED_MEMUSAGE**: --memory-limit (64)

**MEMCACHED_MAXCONN**: --conn-limit (1024)

**MEMCACHED_THREADS**: --threads (4)

**MEMCACHED_REQUESTS_PER_EVENT**: --max-req-per-event (20)

See Memcache documentation for details around what the options do.
