# docker build --no-cache --progress=plain -t tobi312/tools:mqtt-forwarder -f mqtt-forwarder.scratch.Dockerfile .
FROM golang:alpine AS builder
SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]
ARG VERSION=master
WORKDIR /app
RUN apk update ; \
    apk add --no-cache git make binutils ; \
    git clone --branch ${VERSION} --single-branch https://git.ypbind.de/repository/mqtt-forwarder.git
WORKDIR /app/mqtt-forwarder/src/mqtt-forwarder
# create go.mod, go.sum and then build
RUN go mod init mqtt-forwarder ; \
    go mod tidy ; \
    go build -o ../../bin/mqtt-forwarder .

#FROM alpine:latest
FROM scratch
ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
LABEL org.opencontainers.image.title="mqtt-forwarder" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Simple MQTT message forwarder to forward messages from one MQTT broker to another MQTT broker" \
      org.opencontainers.image.documentation="" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://git.ypbind.de/cgit/mqtt-forwarder/"
#RUN apk add --no-cache ca-certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder --chown=1000:1000 /app/mqtt-forwarder/bin/mqtt-forwarder /usr/local/bin/mqtt-forwarder
COPY --from=builder --chown=1000:1000 /app/mqtt-forwarder/example/config.ini /etc/mqtt-forwarder/config.ini
USER 1000:1000
ENTRYPOINT ["mqtt-forwarder"]
#CMD ["--help"]
CMD ["--config=/etc/mqtt-forwarder/config.ini"]