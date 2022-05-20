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
	
# Storage Tools	
RUN apk add --no-cache \
        aws-cli>1.19 \
        samba-client>4.15 \
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
