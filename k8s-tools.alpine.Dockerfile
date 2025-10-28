# docker build --no-cache --progress=plain -t tobi312/tools:k8s -f k8s-tools.alpine.Dockerfile .
FROM alpine:latest AS production

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="K8s-Tools" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Tools for use and deploy on K8s." \
      org.opencontainers.image.documentation="" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="WTFPL" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

RUN \
    apk --no-cache add \
        bash \
        git \
        tar \
        gettext-envsubst \
        #curl \
        #etcd-ctl \
        #kubectl \
        #helm \
        #jq \
        #yq-go \
        make \
    ; \
    echo ""

# https://hub.docker.com/r/tobi312/tools/tags?name=static
COPY --from=tobi312/tools:static-curl /usr/bin/curl /usr/local/bin/curl
COPY --from=tobi312/tools:static-etcdctl /usr/local/bin/etcdctl /usr/local/bin/etcdctl
COPY --from=tobi312/tools:static-kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=tobi312/tools:static-helm /usr/local/bin/helm /usr/local/bin/helm
COPY --from=tobi312/tools:static-helm /root/.local/share/helm/plugins /root/.local/share/helm/plugins
COPY --from=tobi312/tools:static-jq /usr/local/bin/jq /usr/local/bin/jq
COPY --from=tobi312/tools:static-yq /usr/local/bin/yq /usr/local/bin/yq
