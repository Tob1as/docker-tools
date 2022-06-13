FROM ghcr.io/tob1asdocker/tools:toolbox

# Database Tools	
RUN apk add --no-cache \
        mariadb-client>10.6 mariadb-backup>10.6 \
        postgresql14-client>14.3 \
        mongodb-tools>4.2 \
        mosquitto-clients>2.0 \
    ; \
    mariadb --version ; \
    psql --version ; \
    mongostat --version | grep mongostat ; \
    echo ">> Databse-Tools installed!"

# Database Tools Part 2 
# mongosh (with nodejs/npm)
RUN \
    apk add --no-cache \
        npm \
    ; \
    npm i -g mongosh ; \
    mongosh --version
# mongosh (with binary, not working on alpine, libresolv error https://jira.mongodb.org/browse/MONGOSH-1246)
#RUN \
#    apk add --no-cache \
#        krb5-libs \
#        gcompat \
#    ; \
#    #ln -s /lib/libc.so.6 /usr/lib/libresolv.so.2 ; \
#    MONGOSH_VERSION="$(curl -s https://api.github.com/repos/mongodb-js/mongosh/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed 's/[^0-9.]*//g')" ; \
#    wget -qO- https://downloads.mongodb.com/compass/mongosh-${MONGOSH_VERSION}-linux-x64.tgz  | tar xfz - --strip-components=2 -C ./ mongosh-${MONGOSH_VERSION}-linux-x64/bin ; \
#    mv mongosh /usr/local/bin/ ; \
#    mv mongosh_*.so /usr/local/lib/ ; \
#    chmod +x /usr/local/bin/mongosh ; \
#    mongosh --version
	
# Storage Tools	
RUN apk add --no-cache \
        aws-cli>1.19 \
        samba-client>4.15 \
        openssh-client \
        sshpass \
        libc6-compat>1.2 \ 
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
    else \
        echo "AZCopy: unsupported arch" ; \
    fi ; \ 
    \
    echo ">> Storage-Tools installed!"
