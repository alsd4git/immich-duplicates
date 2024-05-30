#!/bin/sh
echo "replacing env at runtime"

# Replace placeholders with actual environment variable values
sed -i "s|__DUPES_JSON_FROM_DOCKER__|${DUPES_JSON_FROM_DOCKER}|g" /usr/share/nginx/html/config.js
sed -i "s|__API_KEY_FROM_DOCKER__|${API_KEY_FROM_DOCKER}|g" /usr/share/nginx/html/config.js
sed -i "s|__IMMICH_URL__|${IMMICH_URL}|g" /usr/share/nginx/html/config.js

# # Start Nginx
# exec "$@"
