ARG ALPINE_TAG=3.21
FROM alpine:${ALPINE_TAG}
ARG ALPINE_TAG

RUN apk add --no-cache vsftpd bash tini busybox-extras

RUN mkdir -p /etc/vsftpd /var/www/html

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21

ENTRYPOINT [ "tini", "-g", "--", "/usr/local/bin/entrypoint.sh" ]
CMD [ "vsftpd", "/etc/vsftpd/vsftpd.conf" ]