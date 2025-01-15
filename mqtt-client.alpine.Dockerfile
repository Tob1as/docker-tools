# build: docker build --no-cache --progress=plain -t tobi312/tools:mqtt-client -f mqtt-client.alpine.Dockerfile .
FROM alpine:latest AS production

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="MQTT-Client" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${BUILD_DATE}.${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Mosquitto Clients for sub/pub data" \
      org.opencontainers.image.documentation="https://mosquitto.org/man/mosquitto_sub-1.html,https://mosquitto.org/man/mosquitto_pub-1.html" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

RUN apk add --no-cache \
        ca-certificates \
        tzdata \
        tini \
        mosquitto-clients \
    ; \
    ln -s /usr/bin/mosquitto_sub /usr/local/bin/sub ; \
    ln -s /usr/bin/mosquitto_pub /usr/local/bin/pub

USER nobody

ENTRYPOINT [ "/sbin/tini", "--" ]