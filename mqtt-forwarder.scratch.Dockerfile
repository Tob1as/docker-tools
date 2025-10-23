# docker build --no-cache --progress=plain --build-arg GO_VERSION=1.25 --build-arg VERSION=1.1.1 -t tobi312/tools:mqtt-forwarder -f mqtt-forwarder.scratch.Dockerfile .
ARG GO_VERSION=1.25
FROM golang:${GO_VERSION}-alpine AS builder
ARG VERSION=master
ENV GOPATH=/go
ENV CGO_ENABLED=0
RUN \
    #apk update ; \
    apk add --no-cache git binutils ; \
    git clone --branch ${VERSION} --single-branch https://git.ypbind.de/repository/mqtt-forwarder.git ${GOPATH}/src/mqtt-forwarder ; \
    #wget -qO- https://git.ypbind.de/cgit/mqtt-forwarder/snapshot/mqtt-forwarder-${VERSION}.tar.gz | tar xzv ; mv mqtt-forwarder-${VERSION} ${GOPATH}/src/mqtt-forwarder ; \
    cd ${GOPATH}/src/mqtt-forwarder/src/mqtt-forwarder ; \
    # create go.mod, go.sum and then build
    go mod init mqtt-forwarder ; \
    go mod tidy ; \
    go build -o ${GOPATH}/bin/mqtt-forwarder . ; \
    ${GOPATH}/bin/mqtt-forwarder --version

FROM scratch AS production
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.opencontainers.image.title="mqtt-forwarder" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Simple MQTT message forwarder to forward messages from one MQTT broker to another MQTT broker" \
      org.opencontainers.image.documentation="https://ypbind.de/maus/projects/mqtt-forwarder/index.html" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://git.ypbind.de/cgit/mqtt-forwarder/"
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder --chown=1000:1000 /go/bin/mqtt-forwarder /usr/local/bin/mqtt-forwarder
COPY --from=builder --chown=1000:1000 /go/src/mqtt-forwarder/example/config.ini /etc/mqtt-forwarder/config.ini
USER 1000:1000
ENTRYPOINT ["mqtt-forwarder"]
#CMD ["--help"]
CMD ["--config=/etc/mqtt-forwarder/config.ini"]