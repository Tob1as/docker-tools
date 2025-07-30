# build: docker build --no-cache --progress=plain --target binary --build-arg ENVSUBST_VERSION=1.4.3 -t tobi312/tools:static-envsubst -f static-envsubst.scratch.Dockerfile .
ARG ENVSUBST_VERSION
FROM alpine:latest AS static-envsubst

ARG ENVSUBST_VERSION

# envsubst https://github.com/a8m/envsubst

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    ARCH=$(uname -m) ; \
    echo ">> ARCH=$ARCH" ; \
    case "$ARCH" in \
      x86_64) TARGETARCH="x86_64" ;; \
      aarch64) TARGETARCH="arm64" ;; \
      *) echo ">> Unknown architecture: $ARCH" && exit 1 ;; \
    esac ; \
    echo ">> Mapped architecture: $TARGETARCH" ; \
    \
    ENVSUBST_VERSION=${ENVSUBST_VERSION:-$(wget -qO- https://api.github.com/repos/a8m/envsubst/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    ENVSUBST_VERSION=$(echo ${ENVSUBST_VERSION} | sed 's/^v//') ; \
    echo ">> ENVSUBST_VERSION=${ENVSUBST_VERSION}" ; \
    wget -q "https://github.com/a8m/envsubst/releases/download/v${ENVSUBST_VERSION}/envsubst-Linux-${TARGETARCH}" -O /usr/local/bin/envsubst ; \
    chmod +x /usr/local/bin/envsubst ; \
    echo ">> envsubst Help:" ; \
    envsubst -help


FROM scratch AS binary

ARG ENVSUBST_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="envsubst" \
      org.opencontainers.image.authors="a8m, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${ENVSUBST_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static envsubst - environment variables substitution for Go" \
      org.opencontainers.image.documentation="https://github.com/a8m/envsubst" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/a8m/envsubst"

COPY --from=static-envsubst /usr/local/bin/envsubst /usr/local/bin/envsubst

ENTRYPOINT ["envsubst"]
#CMD ["-help"]