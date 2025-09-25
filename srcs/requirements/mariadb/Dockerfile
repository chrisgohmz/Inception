ARG ALPINE_TAG=3.21
FROM alpine:${ALPINE_TAG}

RUN apk add --no-cache mariadb mariadb-client bash tini

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME [ "/var/lib/mysql" ]

EXPOSE 3306
ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
CMD [ "mariadbd", "--user=mysql", "--bind-address=0.0.0.0", "--port=3306", "--skip-networking=0" ]