# build: docker build --no-cache --progress=plain --target binary -t tobi312/tools:static-ssh-tools -f static-ssh-tools.Dockerfile .
FROM alpine:latest AS builder

ARG OPENSSH_VERSION=10.2p1
ARG SSHPASS_VERSION=1.10
ARG XXHASH_VERSION=0.8.3
ARG RSYNC_VERSION=3.4.1
ARG AUTOSSH_VERSION=1.4g

ARG VCS_REF

ENV PREFIX=/usr/local/bin

LABEL org.opencontainers.image.title="Static SSH Tools"\
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

WORKDIR /usr/src

RUN apk add --no-cache \
    curl \
    git \
    linux-headers \
    build-base \
    musl-dev \
    gcc \
    make \
    autoconf \
    automake \
    libtool \
    #openssh-client \
    openssl-dev \
    openssl-libs-static \
    zlib-dev \
    zlib-static \
    xxhash-dev \
    #xxhash-static \
    lz4-dev \
    lz4-static \
    zstd-dev \
    zstd-static \
    popt-dev \
    popt-static \
    gnupg

# https://www.openssh.com/ + https://github.com/openssh/openssh-portable
RUN curl -LO https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$OPENSSH_VERSION.tar.gz && \
    #curl -Ls https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/RELEASE_KEY.asc | gpg --import && \
    #curl -LO https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$OPENSSH_VERSION.tar.gz.asc && \
    #gpg --verify openssh-$OPENSSH_VERSION.tar.gz.asc openssh-$OPENSSH_VERSION.tar.gz && \
    tar xzf openssh-$OPENSSH_VERSION.tar.gz && \
    cd openssh-$OPENSSH_VERSION && \
    ./configure \
        --with-ldflags="-static" \
        --with-cflags="-static" \
    && \
    make -j$(nproc) ssh sftp scp ssh-keygen ssh-keyscan && \
    strip ssh && strip sftp && strip scp && strip ssh-keygen && strip ssh-keyscan && \
    install -m 755 ssh $PREFIX/ssh && \
    install -m 755 sftp $PREFIX/sftp && \
    install -m 755 scp $PREFIX/scp && \
    install -m 755 ssh-keygen $PREFIX/ssh-keygen && \
    install -m 755 ssh-keyscan $PREFIX/ssh-keyscan && \
    cd ..

# https://sourceforge.net/projects/sshpass/
RUN curl -LO http://sourceforge.net/projects/sshpass/files/sshpass-$SSHPASS_VERSION.tar.gz && \
    tar xzf sshpass-$SSHPASS_VERSION.tar.gz && \
    cd sshpass-$SSHPASS_VERSION && \
    ./configure \
        LDFLAGS="-static" \
        CFLAGS="-static" \
    && \
    make -j$(nproc) && \
    strip sshpass && \
    install -m 755 sshpass $PREFIX/sshpass && \
    cd ..

# https://cyan4973.github.io/xxHash/  (xxhash(-static) need for rsync)
RUN curl -LO https://github.com/Cyan4973/xxHash/archive/refs/tags/v${XXHASH_VERSION}.tar.gz && \
    tar xzf v${XXHASH_VERSION}.tar.gz && \
    cd xxHash-${XXHASH_VERSION} && \
    make -j$(nproc) && \
    make install PREFIX=/usr/local && \
    cd .. && rm -rf xxHash-${XXHASH_VERSION} v${XXHASH_VERSION}.tar.gz

# https://rsync.samba.org/ + https://github.com/RsyncProject/rsync
RUN curl -LO https://download.samba.org/pub/rsync/src/rsync-$RSYNC_VERSION.tar.gz && \
    ##gpg --keyserver hkps://keys.openpgp.org --recv-keys 9FEF112DCE19A0DC7E882CB81BB24997A8535F6F && \
    #curl -Ls "https://keys.openpgp.org/vks/v1/by-fingerprint/9FEF112DCE19A0DC7E882CB81BB24997A8535F6F" | gpg --import && \
    #curl -LO https://download.samba.org/pub/rsync/src/rsync-$RSYNC_VERSION.tar.gz.asc && \
    #gpg --verify rsync-$RSYNC_VERSION.tar.gz.asc rsync-$RSYNC_VERSION.tar.gz && \
    tar xzf rsync-$RSYNC_VERSION.tar.gz && \
    cd rsync-$RSYNC_VERSION && \
    #./configure --help && \
    ./configure \
        LDFLAGS="-static" \
        CFLAGS="-static" \
    && \
    make -j$(nproc) && \
    strip rsync && \
    install -m 755 rsync $PREFIX/rsync && \
    cd ..

# https://www.harding.motd.ca/autossh/
RUN curl -LO https://www.harding.motd.ca/autossh/autossh-${AUTOSSH_VERSION}.tgz && \
    #curl -LO https://www.harding.motd.ca/autossh/autossh-${AUTOSSH_VERSION}.cksums && \
    ##awk '/SHA256/ {print $4, "autossh-'$AUTOSSH_VERSION'.tgz"}' autossh-$AUTOSSH_VERSION.cksums | sha256sum -c - && \
    #echo "$(grep 'SHA256' autossh-$AUTOSSH_VERSION.cksums | cut -d ' ' -f 4)  autossh-$AUTOSSH_VERSION.tgz" | sha256sum -c - && \
    tar xzf autossh-${AUTOSSH_VERSION}.tgz && \
    cd autossh-${AUTOSSH_VERSION} && \
    VER=${AUTOSSH_VERSION:-$(grep '^VER=' Makefile.in | sed 's/VER=[ \t]*//')} && \
    echo "AUTOSSH_VER=$VER" && \
    ./configure \
        CC=gcc \
        CFLAGS="-static -D__progname=__autossh_progname" \
        LDFLAGS="-static" \
        --with-ssh=$PREFIX/ssh \
    && \
    make CFLAGS="-static -DVER=\\\"$VER\\\"" && \
    strip autossh && \
    install -m 755 autossh $PREFIX/autossh && \
    cd ..

RUN ls -lah

FROM busybox:stable-uclibc AS debug-shell

ARG VCS_REF

LABEL org.opencontainers.image.title="Static SSH Tools"\
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=builder /usr/local/bin/ssh /usr/local/bin/ssh
COPY --from=builder /usr/local/bin/sftp /usr/local/bin/sftp
COPY --from=builder /usr/local/bin/scp /usr/local/bin/scp
COPY --from=builder /usr/local/bin/ssh-keygen /usr/local/bin/ssh-keygen
COPY --from=builder /usr/local/bin/ssh-keyscan /usr/local/bin/ssh-keyscan
COPY --from=builder /usr/local/bin/sshpass /usr/local/bin/sshpass
COPY --from=builder /usr/local/bin/rsync /usr/local/bin/rsync
COPY --from=builder /usr/local/bin/autossh /usr/local/bin/autossh

FROM gcr.io/distroless/static-debian12:nonroot AS production

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Static SSH Tools" \
      #org.opencontainers.image.vendor="" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static SSH Tools: SSH, SFTP, SCP, SSH-KEYGEN, SSHPASS, RSYNC and AUTOSSH." \
      org.opencontainers.image.documentation="https://github.com/Tob1as/docker-tools/" \
      org.opencontainers.image.base.name="gcr.io/distroless/static-debian12:nonroot" \
      org.opencontainers.image.licenses="WTFPL" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=builder /usr/local/bin/ssh /usr/local/bin/ssh
COPY --from=builder /usr/local/bin/sftp /usr/local/bin/sftp
COPY --from=builder /usr/local/bin/scp /usr/local/bin/scp
COPY --from=builder /usr/local/bin/ssh-keygen /usr/local/bin/ssh-keygen
#COPY --from=builder /usr/local/bin/ssh-keyscan /usr/local/bin/ssh-keyscan
COPY --from=builder /usr/local/bin/sshpass /usr/local/bin/sshpass
COPY --from=builder /usr/local/bin/rsync /usr/local/bin/rsync
COPY --from=builder /usr/local/bin/autossh /usr/local/bin/autossh

FROM scratch AS binary

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Static SSH Tools" \
      #org.opencontainers.image.vendor="" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static SSH Tools: SSH, SFTP, SCP, SSH-KEYGEN, SSHPASS, RSYNC and AUTOSSH." \
      org.opencontainers.image.documentation="https://github.com/Tob1as/docker-tools/" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="WTFPL" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=builder /usr/local/bin/ssh /usr/local/bin/ssh
COPY --from=builder /usr/local/bin/sftp /usr/local/bin/sftp
COPY --from=builder /usr/local/bin/scp /usr/local/bin/scp
COPY --from=builder /usr/local/bin/ssh-keygen /usr/local/bin/ssh-keygen
#COPY --from=builder /usr/local/bin/ssh-keyscan /usr/local/bin/ssh-keyscan
COPY --from=builder /usr/local/bin/sshpass /usr/local/bin/sshpass
COPY --from=builder /usr/local/bin/rsync /usr/local/bin/rsync
COPY --from=builder /usr/local/bin/autossh /usr/local/bin/autossh

COPY <<EOF /etc/passwd
root:x:0:0:root:/root:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/:/sbin/nologin
EOF

COPY <<EOF /etc/group
root:x:0:root
nobody:x:65534:
EOF

#USER nobody:nobody

#ENTRYPOINT ["ssh"]
#ENTRYPOINT ["sftp"]
#ENTRYPOINT ["scp"]
#ENTRYPOINT ["ssh-keygen"]
#ENTRYPOINT ["rsync"]
#ENTRYPOINT ["autossh"]

#CMD ["-V"]
#CMD ["--help"]