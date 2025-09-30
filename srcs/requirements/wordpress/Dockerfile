ARG ALPINE_TAG=3.21

FROM alpine:${ALPINE_TAG}

ARG ALPINE_TAG
ARG WP_VERSION=6.8.2
ARG WPCLI_VERSION=2.12.0

ENV PHP_INI_DIR=/etc/php84

RUN set -eux; \
    if ! grep -q '^www-data:' /etc/group; then addgroup -g 82 -S www-data; fi; \
    if ! id -u www-data >/dev/null 2>&1; then adduser -u 82 -D -S -H -G www-data -s /sbin/nologin www-data; fi

RUN apk add --no-cache \
    php84 php84-fpm php84-mysqli php84-json php84-session php84-cli php84-ctype\
    php84-phar php84-iconv php84-curl php84-zip php84-gd php84-tokenizer \
    php84-mbstring php84-xml php84-dom php84-simplexml php84-openssl php84-pecl-redis \
    curl bash tar tini mariadb-client ca-certificates msmtp \
    && ln -sf /usr/bin/php84 /usr/bin/php

RUN sed -i 's|^;*listen = .*|listen = 9000|' ${PHP_INI_DIR}/php-fpm.d/www.conf \
    && sed -i 's|^user = .*|user = www-data|' ${PHP_INI_DIR}/php-fpm.d/www.conf \
    && sed -i 's|^group = .*|group = www-data|' ${PHP_INI_DIR}/php-fpm.d/www.conf \
    && sed -i 's|^;*clear_env = .*|clear_env = no|' ${PHP_INI_DIR}/php-fpm.d/www.conf

WORKDIR /var/www/html

RUN curl -fsSL -o /usr/local/bin/wp https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar \
    && chmod +x /usr/local/bin/wp

RUN curl -fsSL -o /tmp/wordpress.tar.gz https://wordpress.org/wordpress-${WP_VERSION}.tar.gz \
    && tar -xzf /tmp/wordpress.tar.gz -C /tmp \
    && rm -rf /tmp/wordpress.tar.gz

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000
ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
CMD [ "php-fpm84", "-F" ]