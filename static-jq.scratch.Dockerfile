# build: docker build --no-cache --progress=plain --target binary --build-arg JQ_VERSION=1.7.1 -t tobi312/tools:static-jq -f static-jq.scratch.Dockerfile .
ARG JQ_VERSION
FROM alpine:latest AS static-jq

ARG JQ_VERSION

# jq https://github.com/jqlang/jq

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    ARCH=$(uname -m) ; \
    echo ">> ARCH=$ARCH" ; \
    case "$ARCH" in \
      x86_64) TARGETARCH="amd64" ;; \
      aarch64) TARGETARCH="arm64" ;; \
      armv7l) TARGETARCH="armhf" ;; \
      riscv64) TARGETARCH="riscv64" ;; \
      ppc64le) TARGETARCH="ppc64el" ;; \
      s390x) TARGETARCH="s390x" ;; \
      *) echo ">> Unknown architecture: $ARCH" && exit 1 ;; \
    esac ; \
    echo ">> Mapped architecture: $TARGETARCH" ; \
    \
    JQ_VERSION=${JQ_VERSION:-$(wget -qO- https://api.github.com/repos/jqlang/jq/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    JQ_VERSION=$(echo ${JQ_VERSION} | sed 's/^jq-//') ; \
    echo ">> JQ_VERSION=${JQ_VERSION}" ; \
    wget -qO /usr/local/bin/jq "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${TARGETARCH}" ; \
    chmod +x /usr/local/bin/jq ; \
    echo ">> JQ_VERSION (check): $(jq --version)" ; \
    echo ">> jq Help:" ; \
    jq --help


FROM scratch AS binary

ARG JQ_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="jq" \
      org.opencontainers.image.authors="jq Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${JQ_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static jq - Command-line JSON processor" \
      org.opencontainers.image.documentation="https://jqlang.org/" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/jqlang/jq"

#COPY --from=ghcr.io/jqlang/jq:latest /usr/local/bin/jq /usr/local/bin/jq
COPY --from=static-jq /usr/local/bin/jq /usr/local/bin/jq

RUN ["jq", "--version"]

ENTRYPOINT ["jq"]
#CMD ["--version"]
#CMD ["--help"]