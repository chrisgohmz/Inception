ARG ALPINE_TAG=3.21
FROM alpine:${ALPINE_TAG}
ARG ALPINE_TAG
ARG MAILPIT_VERSION=1.27.9

RUN apk add --no-cache ca-certificates bash tini wget tar

WORKDIR /tmp
RUN set -eux; \
    ARCH="$(uname -m)"; case "$ARCH" in x86_64) GOARCH=amd64 ;; aarch64|arm64) GOARCH=arm64 ;; *) echo "Unsupported architecture: $ARCH"; exit 1 ;; esac; \
    URL="https://github.com/axllent/mailpit/releases/download/v${MAILPIT_VERSION}/mailpit-linux-${GOARCH}.tar.gz"; \
    wget -O mp.tgz "$URL"; \
    tar -xzf mp.tgz mailpit && rm -f mp.tgz; \
    install -m 0755 mailpit /usr/local/bin/mailpit && rm -f mailpit

RUN adduser -S -D -H -u 82 -g 'www-data' www-data || true \
    && mkdir -p /data && chown -R www-data:www-data /data

USER www-data
EXPOSE 8025 1025
ENTRYPOINT [ "tini", "-g", "--" ]
CMD [ "mailpit" ]
