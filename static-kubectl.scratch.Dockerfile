# build: docker build --no-cache --progress=plain --target binary --build-arg KUBECTL_VERSION=1.33.0 -t tobi312/tools:static-kubectl -f static-kubectl.scratch.Dockerfile .
ARG KUBECTL_VERSION
FROM golang:alpine AS static-kubectl

ARG KUBECTL_VERSION

# kubectl https://github.com/kubernetes/kubectl , https://kubernetes.io/releases/download/ , https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

RUN \
    OS="$(go env GOOS)" ; \
    ARCH="$(go env GOARCH)" ; \
    TARGETARCH="${ARCH}" ; \
    \
    KUBECTL_VERSION=${KUBECTL_VERSION:-$(wget -qO- https://dl.k8s.io/release/stable.txt)} ; \
    KUBECTL_VERSION=$(echo ${KUBECTL_VERSION} | sed 's/^v//') ; \
    echo ">> KUBECTL_VERSION=${KUBECTL_VERSION}" ; \
    wget -qO /usr/local/bin/kubectl "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/${OS}/${TARGETARCH}/kubectl" ; \
    chmod +x /usr/local/bin/kubectl ; \
    echo ">> KUBECTL_VERSION (check): $(kubectl version --client | grep Client)" ; \
    echo ">> kubectl Help:" ; \
    kubectl --help


FROM scratch AS binary

ARG KUBECTL_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="kubectl" \
      org.opencontainers.image.authors="Kubernetes Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${KUBECTL_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static kubectl - Kubernetes command-line tool" \
      org.opencontainers.image.documentation="https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://kubernetes.io/releases/download/"

COPY --from=static-kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl

RUN ["kubectl", "version", "--client"]

ENTRYPOINT ["kubectl"]
#CMD ["version"]
#CMD ["--help"]