FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="ToolBox" \
	org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
	#org.opencontainers.image.version="${VCS_REF}" \
	org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.revision="${VCS_REF}" \
	org.opencontainers.image.description="ToolBox:  docker run --rm --name toolbox -d tobi312/tools:toolbox && docker exec -it toolbox sh && nc -zv -w 3 <HOST> <PORT>" \
	#org.opencontainers.image.documentation="https://github.com/Tob1asDocker/tools/blob/main/README.md" \
	#org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
	org.opencontainers.image.licenses="Apache-2.0" \
	org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
	org.opencontainers.image.source="https://github.com/Tob1asDocker/tools"

RUN apk add --no-cache \
    bash \
    git \
    nano \
    wget \
    curl \
    iputils \
    netcat-openbsd \
    tzdata \
    zip unzip \
    xz \
    tree \
    patch \
    screen \
    tmux \
    openssh-client \
    rsync \
    #autossh \
    ca-certificates \
    openssl \
    pwgen \
    makepasswd \
    jq \
    ; \
    echo "Tools installed!"

# Database Tools	
#RUN apk add --no-cache \
#    mariadb-client>10.6 \
#    mosquitto-clients>2.0.10 \
#    postgresql14-client \
#    ; \
#    echo "Databse-Tools installed!"

ENTRYPOINT ["/bin/sh", "-c", "--"]
CMD ["while true; do sleep 60; done;"]