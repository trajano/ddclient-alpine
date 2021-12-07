FROM alpine:latest

RUN apk upgrade --no-cache
COPY ddclient /usr/sbin/ddclient
RUN apk add --no-cache perl perl-io-socket-ssl nano
COPY ddclient.conf /etc/ddclient.conf.original
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
