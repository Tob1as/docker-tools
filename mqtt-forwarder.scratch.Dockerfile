# docker build --no-cache --progress=plain -t tobi312/tools:mqtt-forwarder -f mqtt-forwarder.scratch.Dockerfile .
FROM golang:alpine AS builder
SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]
ARG VERSION=master
ENV GO111MODULE=auto
RUN apk update ; \
    apk add --no-cache git make binutils ; \
    git clone --branch ${VERSION} --single-branch https://github.com/Bobobo-bo-Bo-bobo/mqtt-forwarder.git ; \
    cd mqtt-forwarder/
WORKDIR /go/mqtt-forwarder
RUN make all

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
      org.opencontainers.image.source="https://github.com/Bobobo-bo-Bo-bobo/mqtt-forwarder"
#RUN apk add --no-cache ca-certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder --chown=1000:1000 /go/mqtt-forwarder/bin/mqtt-forwarder /usr/local/bin/mqtt-forwarder
COPY --from=builder --chown=1000:1000 /go/mqtt-forwarder/example/config.ini /etc/mqtt-forwarder/config.ini
USER 1000:1000
ENTRYPOINT ["mqtt-forwarder"]
#CMD ["--help"]
CMD ["--config=/etc/mqtt-forwarder/config.ini"]