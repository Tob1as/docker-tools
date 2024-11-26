FROM golang:alpine AS builder

ARG VERSION

# Proxyscotch
RUN \
    apk add --no-cache git ; \
    VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/hoppscotch/proxyscotch/tags | grep 'name' | cut -d\" -f4 | sort -r | sed -n 's/^v[0-9]\+\.[0-9]\+\.[0-9]\+$/&/p' | head -1)} ; \
    echo "Proxyscotch Version = ${VERSION}" ; \
    BUILD_OS=$(go env GOOS) ; \
    BUILD_ARCH=$(go env GOARCH) ; \
    cd /go ; \
    git clone --branch ${VERSION} --single-branch https://github.com/hoppscotch/proxyscotch.git ./proxyscotch ; \
    cd /go/proxyscotch ; \
    # prepare for other arch https://github.com/hoppscotch/proxyscotch/blob/master/build.sh#L329
    sed -i "s/amd64/${BUILD_ARCH}/" build.sh ; \
    ./build.sh ${BUILD_OS} server ; \
    cp ./out/${BUILD_OS}-server/proxyscotch-server-${BUILD_OS}-${BUILD_ARCH}-${VERSION} /usr/local/bin/proxyscotch ; \
    proxyscotch --help

# CAs
#COPY *.crt /usr/local/share/ca-certificates/
#RUN \
#    update-ca-certificates


FROM scratch

ARG VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Proxyscotch" \
      org.opencontainers.image.vendor="" \
      org.opencontainers.image.authors="" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="A simple proxy server created for Hoppscotch <https://github.com/hoppscotch/hoppscotch>." \
      org.opencontainers.image.documentation="https://github.com/hoppscotch/proxyscotch" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/hoppscotch/proxyscotch"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder --chown=1000:100 /usr/local/bin/proxyscotch /usr/local/bin/proxyscotch

EXPOSE 9159/tcp
USER 1000:100
ENTRYPOINT ["proxyscotch"]
CMD ["--host", "0.0.0.0:9159"]