# docker build --no-cache --progress=plain --build-arg VERSION=v0.15.0 -t tobi312/tools:postgres-exporter -f postgres-exporter.scratch.Dockerfile .
FROM golang:alpine AS builder

ARG VERSION

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

# hadolint ignore=SC2086
RUN \
    OS="$(go env GOOS)" ; \
    ARCH="$(go env GOARCH)" ; \
    [ "$ARCH" = "arm" ] && ARCH="armv7" || true ; \
    echo "OS=${OS} ARCH=${ARCH}" ; \
    VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/prometheus-community/postgres_exporter/releases/latest | grep 'tag_name' | cut -d\" -f4 | head -1)} ; \
    echo "VERSION=${VERSION}" ; \
    wget -qO- https://github.com/prometheus-community/postgres_exporter/releases/download/${VERSION}/postgres_exporter-${VERSION:1}.${OS}-${ARCH}.tar.gz | tar xvz -C /tmp ; \
    mv /tmp/postgres_exporter-${VERSION:1}.${OS}-${ARCH} /tmp/postgres_exporter ;\
    chmod +x /tmp/postgres_exporter/postgres_exporter ; \
    ls -lah /tmp/postgres_exporter

FROM scratch AS production

ARG VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Prometheus PostgreSQL Exporter" \
      org.opencontainers.image.authors="Prometheus Community" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Metrics for PostgreSQL Database" \
      org.opencontainers.image.documentation="https://github.com/prometheus-community/postgres_exporter" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/prometheus-community/postgres_exporter"

COPY --from=builder --chown=65534:65534 /tmp/postgres_exporter/postgres_exporter /bin/postgres_exporter

EXPOSE 9187/tcp
# user: nobody
USER 65534
ENTRYPOINT [ "/bin/postgres_exporter" ]
#CMD ["--help"]