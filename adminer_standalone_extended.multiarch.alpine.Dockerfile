FROM adminer:standalone

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Adminer" \
    #org.opencontainers.image.authors="Docker Community" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.description="Adminer: Database management in a single PHP file." \
    org.opencontainers.image.documentation="https://hub.docker.com/_/adminer" \
    org.opencontainers.image.base.name="docker.io/library/adminer:standalone" \
    #org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
    org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

# switch user
USER root

RUN set -eux ; \
    installPackages=' \
        php7.4-mongodb \
    ' ; \
    apt-get update ; \
    apt-get install -y $installPackages --no-install-recommends ; \
    rm -rf /var/lib/apt/lists/*

# switch user back
USER adminer