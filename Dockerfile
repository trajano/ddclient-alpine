FROM alpine:latest

RUN apk upgrade --no-cache
RUN apk add --no-cache perl perl-io-socket-ssl ca-certificates openssl
COPY ddclient /usr/sbin/ddclient
COPY entrypoint.sh /entrypoint.sh
COPY ddclient.conf /etc/ddclient.conf.original
CMD ["/entrypoint.sh"]
