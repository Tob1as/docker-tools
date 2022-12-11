FROM ghcr.io/tob1as/docker-tools:toolbox

# Database Tools	
RUN apk add --no-cache \
        mariadb-client mariadb-backup \
        postgresql14-client \
        mongodb-tools \
        mosquitto-clients \
    ; \
    mariadb --version ; \
    psql --version ; \
    mongostat --version | grep mongostat ; \
    echo ">> Databse-Tools Part 1 installed!"

# Database Tools Part 2 (npm packages)
# mongosh (as nodejs/npm package; binary not working on alpine, see https://jira.mongodb.org/browse/MONGOSH-1246)
# and 
# elasticdump (multielasticdump)
RUN \
    apk add --no-cache \
        npm \
    ; \
    npm i -g mongosh ; \
    mongosh --version ; \
    npm i -g elasticdump ; \
    elasticdump --version ; \
    echo ">> Databse-Tools Part 2 (via npm) installed!"

# Datbase Tools Part 3
#COPY --from=ghcr.io/yannh/redis-dump-go:latest-alpine /redis-dump-go /usr/local/bin/redis-dump-go
COPY --from=redis:alpine /usr/local/bin/redis-cli /usr/local/bin/redis-cli
#RUN \
#    redis-cli --version ; \
#    echo ">> Databse-Tools Part 3 (via COPY) installed!"
	
# Storage Tools	
RUN apk add --no-cache \
        aws-cli \
        samba-client \
        openssh-client \
        rsync \
        sshpass \
        libc6-compat \ 
    ; \
    aws --version ; \
    smbclient --version ; \
    \
    ARCH=`uname -m` ; \
    echo "ARCH=$ARCH" ; \
    if [ "$ARCH" == "x86_64" ]; then \
        echo "AZCopy: install on x86_64 (amd64) arch" ; \
        # AzCopy need libc6-compat, see https://github.com/Azure/azure-storage-azcopy/issues/621#issuecomment-538617518
        wget -qO- https://aka.ms/downloadazcopy-v10-linux  | tar xfz - --strip-components=1 -C /usr/local/bin/ ; chmod +x /usr/local/bin/azcopy ; \
        azcopy --version ; \
    elif [ "$ARCH" == "aarch64" ]; then \
        echo "AZCopy: install on aarch64 (arm64) arch" && \
        wget -qO- https://aka.ms/downloadazcopy-v10-linux-arm64  | tar xfz - --strip-components=1 -C /usr/local/bin/ ; chmod +x /usr/local/bin/azcopy ; \
        azcopy --version ; \
    else \
        echo "AZCopy: unsupported arch" ; \
    fi ; \ 
    \
    echo ">> Storage-Tools installed!"
