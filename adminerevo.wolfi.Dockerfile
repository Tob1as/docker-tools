#FROM ghcr.io/shyim/adminerevo:latest
FROM shyim/adminerevo:latest

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="AdminerEvo" \
    #org.opencontainers.image.authors="AdminerEvo community" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.revision="${VCS_REF}" \
    org.opencontainers.image.description="AdminerEvo: Database management in a single PHP file." \
    org.opencontainers.image.documentation="https://github.com/adminerevo/adminerevo & https://github.com/shyim/adminerevo-docker" \
    org.opencontainers.image.base.name="docker.io/shyim/adminerevo:latest & cgr.dev/chainguard/wolfi-base:latest" \
    #org.opencontainers.image.licenses="Apache-2.0|GPL-2.0" \
    org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
    org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

# switch user
USER root

RUN set -x ; \
    PHP_VERSION=$(php -v | awk '/^PHP/ {print $2}' | cut -d'.' -f1,2) ; \
    installPackages=" \
        php-${PHP_VERSION}-pecl-mongodb \
        #php-${PHP_VERSION}-pecl-sqlsrv \
        #php-${PHP_VERSION}-pecl-pdosqlsrv \
        #php-${PHP_VERSION}-odbc \
        #php-${PHP_VERSION}-pdo_odbc \
        #php-${PHP_VERSION}-pdo_dblib \
        #netcat-openbsd \
    " ; \
    apk add --no-cache $installPackages

# switch user back
USER nonroot