# docker build --no-cache --progress=plain -t tobi312/tools:prometheus-mqtt-transport -f prometheus-mqtt-transport.debian.Dockerfile .
FROM rust:1.82-slim-bookworm AS builder

ARG VERSION=master
ENV RUST_BACKTRACE=1

RUN apt update && apt install -y pkg-config libssl-dev cmake git

WORKDIR /usr/src/

RUN \
    git clone --branch ${VERSION} --single-branch https://git.ypbind.de/repository/prometheus-mqtt-transport.git prometheus-mqtt-transport
    #wget -qO- https://git.ypbind.de/cgit/prometheus-mqtt-transport/snapshot/prometheus-mqtt-transport-${VERSION}.tar.gz | tar xzv ; mv prometheus-mqtt-transport-${VERSION} prometheus-mqtt-transport

WORKDIR /usr/src/prometheus-mqtt-transport
#COPY . .

RUN \
    make all ; \
    #cargo build --release ; \
    ls -lah /usr/src/prometheus-mqtt-transport/target/release


# https://github.com/GoogleContainerTools/distroless
# hadolint ignore=DL3006
FROM gcr.io/distroless/cc-debian12:latest AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.title="prometheus-mqtt-transport" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Scrape Prometheus exporter, transport data over MQTT and expose transported metric data to Prometheus" \
      org.opencontainers.image.documentation="https://ypbind.de/maus/projects/prometheus-mqtt-transport/index.html" \
      org.opencontainers.image.base.name="gcr.io/distroless/cc-debian12:latest" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://git.ypbind.de/cgit/prometheus-mqtt-transport/"

# certs
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# binaries
COPY --from=builder --chown=nobody:nogroup /usr/src/prometheus-mqtt-transport/target/release/prom2mqtt-fetch /usr/local/bin/prom2mqtt-fetch
COPY --from=builder --chown=nobody:nogroup /usr/src/prometheus-mqtt-transport/target/release/prom2mqtt-export /usr/local/bin/prom2mqtt-export

# examples
COPY --from=builder --chown=nobody:nogroup /usr/src/prometheus-mqtt-transport/examples/fetch.yaml /etc/prometheus-mqtt-transport/fetch.yaml
COPY --from=builder --chown=nobody:nogroup /usr/src/prometheus-mqtt-transport/examples/export.yaml /etc/prometheus-mqtt-transport/export.yaml

USER nobody

#EXPOSE 9999/tcp
#ENTRYPOINT ["prom2mqtt-fetch"]
#ENTRYPOINT ["prom2mqtt-export"]
#CMD ["--help"]