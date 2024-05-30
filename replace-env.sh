#!/bin/sh
echo "replacing env at runtime"

# Replace placeholders with actual environment variable values
sed -i "s|__DUPES_JSON_FROM_DOCKER__|${DUPES_JSON_FROM_DOCKER}|g" /usr/share/nginx/html/config.js

# # Start Nginx
# exec "$@"
