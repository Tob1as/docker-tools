# build: docker build --no-cache --progress=plain --target binary --build-arg ETCD_VERSION=v3.6.5 -t tobi312/tools:static-etcdctl -f static-etcdctl.scratch.Dockerfile .
ARG ETCD_VERSION
FROM golang:alpine AS static-etcd

ARG ETCD_VERSION

# etcd https://github.com/etcd-io/etcd

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    OS="$(go env GOOS)" ; \
    ARCH="$(go env GOARCH)" ; \
    TARGETARCH="${ARCH}" ; \
    \
    ETCD_VERSION=${ETCD_VERSION:-$(wget -qO- https://api.github.com/repos/etcd-io/etcd/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    echo ">> ETCD_VERSION=${ETCD_VERSION}" ; \
    wget -qO- "https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-${OS}-${TARGETARCH}.tar.gz" | tar -zxf - --strip-components=1 -C /usr/local/bin/  etcd-${ETCD_VERSION}-${OS}-${TARGETARCH}/etcdctl ; \
    chmod +x /usr/local/bin/etcdctl ; \
    echo ">> ETCD_VERSION (check): $(etcdctl version)" ; \
    echo ">> etcdctl Help:" ; \
    etcdctl --help


FROM scratch AS binary

ARG ETCD_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="etcdctl" \
      org.opencontainers.image.authors="etcd Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${ETCD_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static etcdctl - CLI for etcd key-value store" \
      org.opencontainers.image.documentation="https://etcd.io/" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/etcd-io/etcd"

COPY --from=static-etcd /usr/local/bin/etcdctl /usr/local/bin/etcdctl

RUN ["etcdctl", "version"]

ENTRYPOINT ["etcdctl"]
#CMD ["version"]
#CMD ["--help"]