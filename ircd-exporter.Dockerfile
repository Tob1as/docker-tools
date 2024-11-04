# docker build --no-cache --progress=plain --build-arg GO_VERSION=1.23 -t tobi312/tools:ircd-exporter -f ircd-exporter.Dockerfile .
ARG GO_VERSION=1.23
FROM golang:${GO_VERSION}-alpine AS builder
ARG VERSION=master
ENV GOPATH=/go
ENV CGO_ENABLED=0

RUN \
    apk add --no-cache git ; \
    git clone --branch ${VERSION} --single-branch https://github.com/dgl/ircd_exporter.git ${GOPATH}/src/ircd_exporter ; \
    cd ${GOPATH}/src/ircd_exporter ; \
    go mod download ; \
    cd ${GOPATH}/src/ircd_exporter/cmd/ircd_exporter/ ; \
    go build -o ${GOPATH}/bin/ircd_exporter . ; \
    ${GOPATH}/bin/ircd_exporter --help

FROM scratch
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.opencontainers.image.title="ircd_exporter" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Prometheus exporter for IRC server state" \
      org.opencontainers.image.documentation="https://github.com/dgl/ircd_exporter/issues/3" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/dgl/ircd_exporter"
COPY --from=builder --chown=1000:1000 /go/bin/ircd_exporter /usr/local/bin/ircd_exporter
USER 1000:1000
EXPOSE 9678/tcp
ENTRYPOINT ["ircd_exporter"]
#CMD ["--help"]