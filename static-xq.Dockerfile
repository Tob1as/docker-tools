# build: docker build --no-cache --progress=plain --target binary --build-arg XQ_VERSION=1.3.0 -t tobi312/tools:static-xq -f static-xq.Dockerfile .
ARG XQ_VERSION
FROM alpine:latest AS static-xq

ARG XQ_VERSION

# xq https://github.com/sibprogrammer/xq

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    ARCH=$(uname -m) ; \
    echo ">> ARCH=$ARCH" ; \
    case "$ARCH" in \
      x86_64) TARGETARCH="amd64" ;; \
      aarch64) TARGETARCH="arm64" ;; \
      armv7l) TARGETARCH="armv7" ;; \
      *) echo ">> Unknown architecture: $ARCH" && exit 1 ;; \
    esac ; \
    echo ">> Mapped architecture: $TARGETARCH" ; \
    \
    XQ_VERSION=${XQ_VERSION:-$(wget -qO- https://api.github.com/repos/sibprogrammer/xq/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    XQ_VERSION=$(echo ${XQ_VERSION} | sed 's/^v//') ; \
    echo ">> XQ_VERSION=${XQ_VERSION}" ; \
    wget -qO- "https://github.com/sibprogrammer/xq/releases/download/v${XQ_VERSION}/xq_${XQ_VERSION}_linux_${TARGETARCH}.tar.gz" | tar xzO xq > /usr/local/bin/xq ; \
    chmod +x /usr/local/bin/xq ; \
    echo ">> XQ_VERSION (check): $(xq --version)" ; \
    echo ">> xq Help:" ; \
    xq --help


FROM scratch AS binary

ARG XQ_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="xq" \
      org.opencontainers.image.authors="xq Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${XQ_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static xq - Command-line XML processor" \
      org.opencontainers.image.documentation="https://github.com/sibprogrammer/xq" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/sibprogrammer/xq"

COPY --from=static-xq /usr/local/bin/xq /usr/local/bin/xq

RUN ["xq", "--version"]

ENTRYPOINT ["xq"]
#CMD ["--version"]
#CMD ["--help"]