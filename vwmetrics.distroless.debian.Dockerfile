# docker build --no-cache --progress=plain -t tobi312/tools:vwmetrics -f vwmetrics.distroless.debian.Dockerfile .
# https://hub.docker.com/_/rust
FROM rust:1-slim AS builder

# v0.1.0
ARG VERSION=master

# hadolint ignore=DL3008
RUN apt-get update; \
    apt-get install -y --no-install-recommends \
        #curl \
        git \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    git clone --branch ${VERSION} --single-branch https://github.com/Tricked-dev/vwmetrics.git /usr/src/vwmetrics

WORKDIR /usr/src/vwmetrics

RUN cargo build --release

# https://github.com/GoogleContainerTools/distroless
# hadolint ignore=DL3007
FROM gcr.io/distroless/cc-debian12:latest AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

LABEL org.opencontainers.image.title="VWMetrics" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Turn your Vaultwarden database into Prometheus metrics." \
      org.opencontainers.image.documentation="https://github.com/Tricked-dev/vwmetrics" \
      org.opencontainers.image.base.name="gcr.io/distroless/cc-debian12:latest" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/Tricked-dev/vwmetrics"

COPY --from=builder --chown=nobody:nogroup /usr/src/vwmetrics/target/release/vwmetrics /usr/local/bin/vwmetrics

USER nobody

ENV HOST=0.0.0.0 PORT=3040

EXPOSE 3040

ENTRYPOINT ["/usr/local/bin/vwmetrics"]
#CMD ["--help"]