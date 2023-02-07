FROM golang:alpine AS builder
ARG AZCOPY_VERSION
SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]
RUN apk update ; \
    apk add --no-cache git curl ; \
    AZCOPY_VERSION=${AZCOPY_VERSION:-$(curl -s https://api.github.com/repos/Azure/azure-storage-azcopy/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    #AZCOPY_VERSION="v10.17.0" ; \
    git clone --branch ${AZCOPY_VERSION} --single-branch https://github.com/Azure/azure-storage-azcopy.git ; \
    cd azure-storage-azcopy/
WORKDIR /go/azure-storage-azcopy
RUN GOOS=linux go build
RUN chmod +x /go/azure-storage-azcopy/azure-storage-azcopy

FROM scratch
ARG VCS_REF
ARG BUILD_DATE
ARG AZCOPY_VERSION
LABEL org.opencontainers.image.title="AzCopy" \
      org.opencontainers.image.description="MinIO is a High Performance Object Storage, API compatible with Amazon S3 cloud storage service." \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${AZCOPY_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.documentation="https://github.com/Azure/azure-storage-azcopy" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"
COPY --from=builder /go/azure-storage-azcopy/azure-storage-azcopy /azcopy
ENTRYPOINT ["/azcopy"]
CMD ["--help"]