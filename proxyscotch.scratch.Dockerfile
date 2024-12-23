FROM golang:alpine AS builder

ARG VERSION

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

WORKDIR /go/src/proxyscotch

# hadolint ignore=DL3018,SC2046
RUN apk add --no-cache git ; \
    #VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/hoppscotch/proxyscotch/tags | grep 'name' | cut -d\" -f4 | sort -r | sed -n 's/^v[0-9]\+\.[0-9]\+\.[0-9]\+$/&/p' | head -1)} ; \
    VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/hoppscotch/proxyscotch/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    echo "Proxyscotch Version = ${VERSION}" ; \
    git clone --branch "${VERSION}" --single-branch https://github.com/hoppscotch/proxyscotch.git . ; \
    export $(grep -v '^#' version.properties | xargs) ; \
    # https://github.com/hoppscotch/proxyscotch/blob/master/build.sh#L217
    GOOS="$(go env GOOS)" GOARCH="$(go env GOARCH)" go build -ldflags "-X main.VersionName=$VERSION_NAME -X main.VersionCode=$VERSION_CODE" -o "${GOPATH}/bin/proxyscotch" server/server.go ; \
    proxyscotch --help


FROM scratch

ARG VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Proxyscotch" \
      #org.opencontainers.image.vendor="" \
      #org.opencontainers.image.authors="" \
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
COPY --from=builder /go/bin/proxyscotch /usr/local/bin/proxyscotch
#COPY --from=builder /go/src/proxyscotch/LICENSE /LICENSE

EXPOSE 9159/tcp
USER 1000:100
ENTRYPOINT ["proxyscotch"]
CMD ["--host", "0.0.0.0:9159"]