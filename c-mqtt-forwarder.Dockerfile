# docker build --no-cache --progress=plain -t tobi312/tools:c-mqtt-forwarder -f c-mqtt-forwarder.Dockerfile .
FROM alpine:latest AS builder

ARG VERSION=1.0.0

RUN \
    apk update ; \
    apk add --no-cache --virtual .build-deps \
        build-base \
        cmake \
        git \
        mosquitto-dev \
        util-linux-dev \
        uthash-dev \
        cjson-dev \
        linux-headers \
        libuuid \
        pcre-dev \
    ; \
    echo "Build requirements installed!"

WORKDIR /usr/src/

RUN \
    #git clone --branch ${VERSION} --single-branch https://git.ypbind.de/repository/c-mqtt-forwarder.git c-mqtt-forwarder
    wget -qO- https://git.ypbind.de/cgit/c-mqtt-forwarder/snapshot/c-mqtt-forwarder-${VERSION}.tar.gz | tar xzv ; mv c-mqtt-forwarder-${VERSION} c-mqtt-forwarder

WORKDIR /usr/src/c-mqtt-forwarder

RUN cmake . ; \
    make ; \
    make install

COPY <<EOF /etc/mqtt-forwarder/config.json
{
  "in": [
    {
      "host": "mqtt-in-1.example.com",
      "port": 8883,
      "topic": "#",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "user": "mqtt-in-1-user",
      "password": "It's so fluffy I'm gonna DIE!",
      "qos": 0,
      "timeout": 60,
      "keepalive": 5,
      "reconnect_delay": 10
    },
    {
      "host": "mqtt-in-2.example.net",
      "port": 1883,
      "topic": "input/topic/no/+/data",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "ssl_auth_public": "/path/to/client/public.PE",
      "ssl_auth_private": "/path/to/client/private.key",
      "qos": 2,
      "timeout": 180
    }
  ],
  "out": [
    {
      "host": "mqtt-out-1.example.com",
      "port": 8883,
      "topic": "output/topic/1",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "user": "mqtt-out-1-user",
      "password": "SO FLUFFY!",
      "qos": 0,
      "timeout": 60,
      "keepalive": 5
    },
    {
      "host": "mqtt-out-2.example.net",
      "port": 1883,
      "topic": "secondary/output/topic/2",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "ssl_auth_public": "/path/to/client/public.pem",
      "ssl_auth_private": "/path/to/client/private.key",
      "qos": 1,
      "timeout": 180
    },
    {
      "host": "mqtt-out-3.example.com",
      "port": 1884,
      "topic": "path/to/topic",
      "insecure_ssl": true,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "user": "mqtt-out-user",
      "password": "Assemble the minions!",
      "qos": 0,
      "timeout": 60,
      "keepalive": 5
    },
    {
      "host": "mqtt-out-4.example.net",
      "port": 2885,
      "topic": "topic/on/out/4",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "ssl_auth_public": "/path/to/client/public.pem",
      "ssl_auth_private": "/path/to/client/private.key",
      "qos": 1
    }
  ]
}
EOF


FROM alpine:latest

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.title="c-mqtt-forwarder" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="MQTT message forwarder to forward MQTT from multiple input brokers to multiple output brokers (fan-in/fan-out)" \
      org.opencontainers.image.documentation="https://ypbind.de/maus/projects/c-mqtt-forwarder/" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://git.ypbind.de/cgit/c-mqtt-forwarder"

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

RUN \
    #apk update ; \
    apk add --no-cache \
        mosquitto-libs \
        cjson \
        libuuid \
        #uthash \
        ca-certificates \
    ; \
    echo "Runtime requirements installed!"

# binary
COPY --from=builder --chown=nobody:nogroup /usr/local/bin/c-mqtt-forwarder /usr/local/bin/c-mqtt-forwarder

# example
COPY --from=builder --chown=nobody:nogroup /etc/mqtt-forwarder/config.json /etc/mqtt-forwarder/config.json

USER nobody

ENTRYPOINT ["c-mqtt-forwarder"]
#CMD ["--help"]
CMD ["--config=/etc/mqtt-forwarder/config.json"]