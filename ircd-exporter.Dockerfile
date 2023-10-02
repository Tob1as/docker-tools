# docker build --no-cache --progress=plain --build-arg GOLANG_VERSION=1.21 -t tobi312/tools:ircd-exporter -f Dockerfile .
ARG GOLANG_VERSION=1.21
FROM golang:${GOLANG_VERSION}-alpine as builder

#ENV GOPATH /go
ENV CGO_ENABLED 0
#ENV GO111MODULE on

RUN \
    apk add --no-cache git ; \
    git clone https://github.com/dgl/ircd_exporter.git ./ircd_exporter ; \
    cd ./ircd_exporter ; \
    go mod download ; \
    cd ./cmd/ircd_exporter/ ; \
    go build 

	
FROM scratch

ARG BUILD_DATE

LABEL org.opencontainers.image.title="ircd_exporter" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.description="Prometheus exporter for IRC server state" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="" \
    org.opencontainers.image.source="https://github.com/dgl/ircd_exporter"

COPY --from=builder --chown=100:100 /go/ircd_exporter/cmd/ircd_exporter/ircd_exporter /usr/local/bin/ircd_exporter

USER 100:100
EXPOSE 9678/tcp
ENTRYPOINT ["ircd_exporter"]
CMD ["--help"]