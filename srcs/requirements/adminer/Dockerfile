ARG ALPINE_TAG=3.21
FROM alpine:${ALPINE_TAG}
ARG ALPINE_TAG

ARG ADMINER_VERSION=5.4.1

RUN apk add --no-cache \
    php84 php84-fpm php84-cli \
    php84-mysqli php84-pdo php84-pdo_mysql php84-session php84-mbstring php84-opcache \
    curl ca-certificates bash tini \
    && ln -s /usr/bin/php84 /usr/bin/php

RUN set -eux; \
    if ! grep -q '^www-data:' /etc/group; then \
        addgroup -g 82 -S www-data; \
    fi; \
    if ! id -u www-data >/dev/null 2>&1; then \
        adduser -u 82 -D -S -H -G www-data -s /sbin/nologin www-data; \
    fi

RUN sed -i 's|^;*listen = .*|listen = 0.0.0.0:9000|' /etc/php84/php-fpm.d/www.conf && \
    sed -i 's|^user = .*|user = www-data|' /etc/php84/php-fpm.d/www.conf && \
    sed -i 's|^group = .*|group = www-data|' /etc/php84/php-fpm.d/www.conf && \
    sed -i 's|^;*clear_env = .*|clear_env = no|' /etc/php84/php-fpm.d/www.conf

WORKDIR /var/www/adminer

RUN set -eux; \
    curl -fL -o adminer.php "https://github.com/vrana/adminer/releases/download/v${ADMINER_VERSION}/adminer-${ADMINER_VERSION}.php"; \
    test -s adminer.php

RUN printf '%s\n' \
    "<?php" \
    "\$GLOBALS['adminer_default_server'] = getenv('ADMINER_DEFAULT_SERVER') ?: 'mariadb';" \
    "require __DIR__ . '/adminer.php';" \
    > index.php && \
    chown -R www-data:www-data /var/www/adminer

EXPOSE 9000
ENTRYPOINT [ "tini", "-g", "--" ]
CMD [ "php-fpm84", "-F" ]