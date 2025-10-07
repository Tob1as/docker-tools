# build: docker build --no-cache --progress=plain -t tobi312/tools:adminer -f adminer_standalone_extended.multiarch.alpine.Dockerfile .
FROM adminer:standalone

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Adminer" \
    #org.opencontainers.image.authors="Community" \
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

# php-extension-installer https://github.com/mlocati/docker-php-extension-installer
#COPY --from=ghcr.io/mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN set -x ; \
    install-php-extensions \
        #pdo_dblib \
        oci8 \
        #interbase \
        mongodb \
    ; \
    echo "PHP extensions installation is complete!"


# switch user
USER adminer