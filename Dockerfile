FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY ./ ./
RUN npm run build

FROM nginx:alpine AS runtime

COPY --from=build /app/dist /usr/share/nginx/html
COPY ./nginx/nginx.conf /etc/nginx

ENV IMMICH_URL=https://immich.example.com
ENV DUPES_JSON_FROM_DOCKER="[]"
ENV API_KEY_FROM_DOCKER=""

RUN mkdir -p /etc/nginx/templates
COPY ./nginx/immich-proxy.conf.template /etc/nginx/templates


COPY ["replace-env.sh", "/docker-entrypoint.d/replace-env.sh"]
RUN chown nginx:nginx /docker-entrypoint.d/replace-env.sh
RUN chmod +x /docker-entrypoint.d/replace-env.sh
