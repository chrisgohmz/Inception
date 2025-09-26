ARG ALPINE_TAG=3.21
FROM alpine:${ALPINE_TAG}
ARG ALPINE_TAG

RUN apk add --no-cache redis tini bash

RUN mkdir -p /etc/redis /data

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6379
VOLUME [ "/data" ]

ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
CMD [ "redis-server", "/etc/redis/redis.conf" ]