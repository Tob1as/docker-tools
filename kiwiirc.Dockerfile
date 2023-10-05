# build: docker build --no-cache --progress=plain -t tobi312/tools:kiwiirc -f kiwiirc.Dockerfile .
ARG KIWIIRC_VERSION
FROM alpine:latest as builder	
ARG KIWIIRC_VERSION
RUN \
    case "$(uname -m)" in \
        x86_64|amd64) TARGETARCH="amd64" ;; \
        arm64|aarch64) TARGETARCH="aarch64" ;; \
        armhf|armv7l|armv6l) TARGETARCH="armhf" ;; \
        *) echo "unknown arch";; \
    esac ; \
    echo "TARGETARCH=${TARGETARCH}" \
    ; \
    KIWIIRC_VERSION=${KIWIIRC_VERSION:-$(wget -qO- https://api.github.com/repos/kiwiirc/kiwiirc/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    echo "KIWIIRC_VERSION=${KIWIIRC_VERSION}" ; \
    KIWIIRC_FILENAME="kiwiirc-server_${KIWIIRC_VERSION}-2_linux_${TARGETARCH}.zip" ; \
    wget https://github.com/kiwiirc/kiwiirc/releases/download/${KIWIIRC_VERSION}/${KIWIIRC_FILENAME} ; \
    unzip ${KIWIIRC_FILENAME} ; \
    rm ${KIWIIRC_FILENAME} ; \
    mv kiwiirc_${KIWIIRC_VERSION}-2_linux_${TARGETARCH} kiwiirc

FROM debian:latest
ARG KIWIIRC_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Kiwi IRC" \
      org.opencontainers.image.authors="Kiwi IRC Developers, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${KIWIIRC_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Kiwi IRC web client: https://kiwiirc.com/ & https://github.com/kiwiirc/kiwiirc" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"


COPY --from=builder /kiwiirc /kiwiirc

COPY <<EOF /kiwiirc/docker-entrypoint.sh
#!/bin/sh
if [ -f /kiwiirc/data/config.conf ]; then
    ln -sf /kiwiirc/data/config.conf
elif [ -d /kiwiirc/data/ ]; then
    cp config.conf /kiwiirc/data/config.conf
    ln -sf /kiwiirc/data/config.conf
fi

if [ -f /kiwiirc/data/config.json ]; then
    (cd www/static; ln -sf /kiwiirc/data/config.json)
elif [ -d /kiwiirc/data ]; then
    cp www/static/config.json /kiwiirc/data
    (cd www/static; ln -sf /kiwiirc/data/config.json)
fi

exec "\$@"
EOF

RUN \
    sed -i 's/^port = 80\b/port = 8080/' /kiwiirc/config.conf ; \
    sed -i 's/^port = 443\b/port = 8443/' /kiwiirc/config.conf ; \
    cp /kiwiirc/config.conf /kiwiirc/config.conf.example ; \
    cp /kiwiirc/www/static/config.json /kiwiirc/www/static/config.json.example ; \
    mkdir -p /kiwiirc/data ; \
    chmod +x /kiwiirc/docker-entrypoint.sh ; \
    chown -R nobody:nogroup /kiwiirc

WORKDIR /kiwiirc
VOLUME /kiwiirc/data
USER nobody
EXPOSE 8080/tcp 8443/tcp

ENTRYPOINT ["/kiwiirc/docker-entrypoint.sh"]
#CMD ["/kiwiirc/kiwiirc", "-config", "config.conf", "-run", "gateway"]
CMD ["/kiwiirc/kiwiirc"]