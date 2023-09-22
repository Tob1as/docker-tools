FROM node:lts-alpine AS builder

ARG VERSION

RUN \
    mkdir /app ; \
    VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/flespi-software/MQTT-Board/tags | grep 'name' | cut -d\" -f4 | head -1)} ; \
    wget -qO- https://github.com/flespi-software/MQTT-Board/archive/${VERSION}.tar.gz  | tar xvz -C /app ; \
    mv /app/MQTT-Board-${VERSION} /app/MQTT-Board ; \
    ls -lah /app/MQTT-Board
	
WORKDIR /app/MQTT-Board

RUN \
    npm install ; \
    NODE_OPTIONS=--openssl-legacy-provider ./node_modules/.bin/quasar build


FROM nginx:alpine

ARG VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="MQTT-Board" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="MQTT-Board: MQTT Web Client Tool (only wss:// connection)" \
      org.opencontainers.image.documentation="https://github.com/flespi-software/MQTT-Board" \
      org.opencontainers.image.base.name="docker.io/library/nginx:alpine" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"
	
SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

COPY --from=builder /app/MQTT-Board/dist/spa /usr/share/nginx/html

EXPOSE 80
