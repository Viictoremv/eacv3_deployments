FROM nginx:stable-alpine

# Apply latest security patches
RUN apk upgrade --no-cache

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
