FROM alpine:3.12
LABEL MAINTAINER Adrian Gschwend <adrian.gschwend@zazuko.com>

# Only update below
ARG HITCH_VERSION=1.7.2

# dependencies
RUN apk --update add bash build-base libev libev-dev automake openssl openssl-dev autoconf curl byacc flex
# get & build
RUN cd /tmp && curl -L https://hitch-tls.org/source/hitch-${HITCH_VERSION}.tar.gz | tar xz
RUN cd /tmp/hitch* && ./configure --with-rst2man=/bin/true
RUN cd /tmp/hitch* && make && make install
RUN mkdir -p /etc/ssl/hitch
RUN adduser -h /var/lib/hitch -s /sbin/nologin -u 1000 -D hitch

# Cleanup
RUN cd / && \
    rm -rf /tmp/* && \
    apk del git build-base libev-dev automake autoconf openssl-dev flex byacc && \
    rm -rf /var/cache/apk/*

ADD start.sh /start.sh

ENV HITCH_PEM    /etc/ssl/hitch/combined.pem
# pelase set backend port to your GRCP container one and frontend to the one you want to expose
ENV HITCH_PARAMS "--backend=[127.0.0.1]:50051 --frontend=[*]:8443+/etc/ssl/hitch/combined.pem"
ENV HITCH_CIPHER ECDHE-RSA-AES128-GCM-SHA256

CMD /start.sh
# set accordingly to exposed port
EXPOSE 8443
