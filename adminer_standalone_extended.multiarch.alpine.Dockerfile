FROM adminer:standalone

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Adminer" \
	#org.opencontainers.image.authors="" \
	org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.revision="${VCS_REF}" \
	org.opencontainers.image.description="Adminer: Database management in a single PHP file." \
	#org.opencontainers.image.documentation="https://github.com/Tob1asDocker/tools/blob/main/README.md#adminer" \
	org.opencontainers.image.base.name="docker.io/library/adminer:standalone" \
	org.opencontainers.image.licenses="Apache-2.0" \
	org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
	org.opencontainers.image.source="https://github.com/Tob1asDocker/tools"

# pdo_dblib (MS SQL) - install by default, oci8 (Oracle), interbase/pdo_firebird (Firebird), mongodb (MongoDB)

# switch user
USER root

# PHP-EXTENSION-INSTALLER
RUN \
    PHP_EXTENSION_INSTALLER_VERSION=$(curl -s https://api.github.com/repos/mlocati/docker-php-extension-installer/releases/latest | grep 'tag_name' | cut -d '"' -f4) ; \
    echo "install-php-extensions Version: ${PHP_EXTENSION_INSTALLER_VERSION}" ; \
    curl -sSL https://github.com/mlocati/docker-php-extension-installer/releases/download/${PHP_EXTENSION_INSTALLER_VERSION}/install-php-extensions -o /usr/local/bin/install-php-extensions ; \
    chmod +x /usr/local/bin/install-php-extensions
	
# PHP-EXTENSIONs
RUN	install-php-extensions \
    #pdo_dblib \
    oci8 \
    #interbase \
    #pdo_firebird \
    mongodb

# switch user back
USER adminer
