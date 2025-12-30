# docker build --no-cache --progress=plain -t tobi312/tools:prometheus-mosquitto-exporter -f prometheus-mosquitto-exporter.debian.Dockerfile .
FROM rust:1.92-slim-trixie AS builder

ARG VERSION=master
ENV RUST_BACKTRACE=1

RUN apt update && apt install -y pkg-config libssl-dev cmake git

WORKDIR /usr/src/

RUN \
    git clone --branch ${VERSION} --single-branch https://git.ypbind.de/repository/prometheus-mosquitto-exporter.git prometheus-mosquitto-exporter
    #wget -qO- https://git.ypbind.de/cgit/prometheus-mosquitto-exporter/snapshot/prometheus-mosquitto-exporter-${VERSION}.tar.gz | tar xzv ; mv prometheus-mosquitto-exporter-${VERSION} prometheus-mosquitto-exporter

WORKDIR /usr/src/prometheus-mosquitto-exporter
#COPY . .

RUN \
    make all ; \
    #cargo build --release ; \
    ls -lah /usr/src/prometheus-mosquitto-exporter/target/release

RUN sed -i '/^\s*broker:/s/tls:/ssl:/' etc/prometheus-mosquitto-exporter.yaml


# https://github.com/GoogleContainerTools/distroless
# hadolint ignore=DL3006
FROM gcr.io/distroless/cc-debian12:latest AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.title="prometheus-mosquitto-exporter" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Export statistics of Mosquitto MQTT broker (topic: \$SYS) to Prometheus" \
      org.opencontainers.image.documentation="https://ypbind.de/maus/projects/prometheus-mosquitto-exporter/" \
      org.opencontainers.image.base.name="gcr.io/distroless/cc-debian12:latest" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://git.ypbind.de/cgit/prometheus-mosquitto-exporter/"

# certs
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# binary
COPY --from=builder --chown=nobody:nogroup /usr/src/prometheus-mosquitto-exporter/target/release/prometheus-mosquitto-exporter /usr/local/bin/prometheus-mosquitto-exporter

# example
COPY --from=builder --chown=nobody:nogroup /usr/src/prometheus-mosquitto-exporter/etc/prometheus-mosquitto-exporter.yaml /etc/prometheus-mosquitto-exporter/config.yaml

USER nobody

#EXPOSE 6883/tcp 9883/tcp
ENTRYPOINT ["prometheus-mosquitto-exporter"]
#CMD ["--help"]
CMD ["--config=/etc/prometheus-mosquitto-exporter/config.yaml"]