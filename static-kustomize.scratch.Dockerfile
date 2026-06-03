# build: docker build --no-cache --progress=plain --target binary --build-arg KUSTOMIZE_VERSION=v5.8.1 -t tobi312/tools:static-kustomize -f static-kustomize.scratch.Dockerfile .
ARG KUSTOMIZE_VERSION
FROM golang:alpine AS static-kustomize

ARG KUSTOMIZE_VERSION

# kustomize https://github.com/kubernetes-sigs/kustomize

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    #apk add --no-cache git ; \
    OS="$(go env GOOS)" ; \
    ARCH="$(go env GOARCH)" ; \
    TARGETARCH="${ARCH}" ; \
    \
    # https://github.com/kubernetes-sigs/kustomize
    KUSTOMIZE_VERSION=${KUSTOMIZE_VERSION:-$(wget -qO- https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    KUSTOMIZE_VERSION=$(echo ${KUSTOMIZE_VERSION} | sed 's/^kustomize\///') ; \
    echo ">> KUSTOMIZE_VERSION=${KUSTOMIZE_VERSION}" ; \
    wget -qO- "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_${OS}_${TARGETARCH}.tar.gz" | tar -xz -C /usr/local/bin/ kustomize ; \
    chmod +x /usr/local/bin/kustomize ; \
    echo ">> KUSTOMIZE_VERSION (check): $(kustomize version)" ; \
    echo ">> kustomize Help:" ; \
    kustomize --help

FROM scratch AS binary

ARG KUSTOMIZE_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="kustomize" \
      org.opencontainers.image.authors="Kustomize Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${KUSTOMIZE_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static Kustomize - Customization of kubernetes YAML configurations" \
      org.opencontainers.image.documentation="https://kustomize.io" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/kubernetes-sigs/kustomize"

COPY --from=static-kustomize /usr/local/bin/kustomize /usr/local/bin/kustomize

RUN ["kustomize", "version"]

ENTRYPOINT ["kustomize"]
#CMD ["version"]
#CMD ["--help"]