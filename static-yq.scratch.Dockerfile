# build: docker build --no-cache --progress=plain --target binary --build-arg YQ_VERSION=4.45.2 -t tobi312/tools:static-yq -f static-yq.scratch.Dockerfile .
ARG YQ_VERSION
FROM golang:alpine AS static-yq

ARG YQ_VERSION

# yq https://github.com/mikefarah/yq

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    OS="$(go env GOOS)" ; \
    ARCH="$(go env GOARCH)" ; \
    TARGETARCH="${ARCH}" ; \
    \
    YQ_VERSION=${YQ_VERSION:-$(wget -qO- https://api.github.com/repos/mikefarah/yq/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    YQ_VERSION=$(echo ${YQ_VERSION} | sed 's/^v//') ; \
    echo ">> YQ_VERSION=${YQ_VERSION}" ; \
    wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_${OS}_${TARGETARCH}" ; \
    chmod +x /usr/local/bin/yq ; \
    echo ">> YQ_VERSION (check): $(yq --version)" ; \
    echo ">> yq Help:" ; \
    yq --help


FROM scratch AS binary

ARG YQ_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="yq" \
      org.opencontainers.image.authors="yq Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${YQ_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static yq - Command-line YAML processor" \
      org.opencontainers.image.documentation="https://mikefarah.gitbook.io/yq/" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/mikefarah/yq"

COPY --from=static-yq /usr/local/bin/yq /usr/local/bin/yq

RUN ["yq", "--version"]

ENTRYPOINT ["yq"]
#CMD ["--version"]
#CMD ["--help"]