# build: docker build --no-cache --progress=plain --target binary --build-arg HELM_VERSION=3.17.3 -t tobi312/tools:static-helm -f static-helm.scratch.Dockerfile .
ARG HELM_VERSION
FROM golang:alpine AS static-helm

ARG HELM_VERSION

# helm https://github.com/helm/helm

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    OS="$(go env GOOS)" ; \
    ARCH="$(go env GOARCH)" ; \
    TARGETARCH="${ARCH}" ; \
    \
    HELM_VERSION=${HELM_VERSION:-$(wget -qO- https://api.github.com/repos/helm/helm/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
    HELM_VERSION=$(echo ${HELM_VERSION} | sed 's/^v//') ; \
    echo ">> HELM_VERSION=${HELM_VERSION}" ; \
    wget -qO- "https://get.helm.sh/helm-v${HELM_VERSION}-${OS}-${TARGETARCH}.tar.gz" | tar -xz --strip-components=1 -C /usr/local/bin/ ${OS}-${TARGETARCH}/helm ; \
    chmod +x /usr/local/bin/helm ; \
    echo ">> HELM_VERSION (check): $(kubectl version)" ; \
    echo ">> helm Help:" ; \
    helm --help


FROM scratch AS binary

ARG HELM_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="helm" \
      org.opencontainers.image.authors="Helm Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${HELM_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static helm - The Kubernetes Package Manager" \
      org.opencontainers.image.documentation="https://helm.sh/docs/intro/install/#from-the-binary-releases" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/helm/helm"

COPY --from=static-helm /usr/local/bin/helm /usr/local/bin/helm

RUN ["helm", "version"]

ENTRYPOINT ["helm"]
#CMD ["version"]
#CMD ["--help"]