FROM adminer:standalone

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
