ARG ALPINE_TAG=3.21
FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache nginx openssl tini bash gettext
RUN mkdir -p /etc/nginx/certs /run/nginx /var/www/html

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /etc/ssl/private && chown -R nginx:nginx /etc/ssl/private

EXPOSE 443
ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
CMD ["nginx", "-g", "daemon off;"]