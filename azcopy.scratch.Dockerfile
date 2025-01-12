# docker build --no-cache --progress=plain -t tobi312/tools:azcopy -f azcopy.scratch.Dockerfile .
FROM golang:alpine AS builder
ARG AZCOPY_VERSION
ENV GOPATH=/go
ENV CGO_ENABLED=0
SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]
WORKDIR /go/src/azure-storage-azcopy
# hadolint ignore=DL3018
RUN apk update ; \
    apk add --no-cache git curl ; \
    AZCOPY_VERSION=${AZCOPY_VERSION:-$(curl -s https://api.github.com/repos/Azure/azure-storage-azcopy/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    #AZCOPY_VERSION="v10.27.1" ; \
    git clone --branch "${AZCOPY_VERSION}" --single-branch https://github.com/Azure/azure-storage-azcopy.git . ; \
    #rm go.mod go.sum && go mod init github.com/Azure/azure-storage-azcopy/v10 && go mod tidy ; \
    GOOS="$(go env GOOS)" GOARCH="$(go env GOARCH)" go build -o ${GOPATH}/bin/azcopy . ; \
    chmod +x ${GOPATH}/bin/azcopy ; \
    azcopy --version

FROM scratch AS production
ARG VCS_REF
ARG BUILD_DATE
ARG AZCOPY_VERSION
LABEL org.opencontainers.image.title="AzCopy" \
      org.opencontainers.image.description="AzCopy is a command-line utility that you can use to copy blobs or files to or from a storage account." \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${AZCOPY_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.documentation="https://github.com/Azure/azure-storage-azcopy" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /go/bin/azcopy /usr/local/bin/azcopy
ENTRYPOINT ["azcopy"]
CMD ["--help"]