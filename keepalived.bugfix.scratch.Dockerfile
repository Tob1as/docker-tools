# docker build --no-cache --progress=plain --build-arg VERSION=v2.3.2 -t tobi312/tools:keepalived -f keepalived.scratch.Dockerfile .
# https://github.com/acassen/keepalived/issues/2107#issuecomment-1049725208
# hadolint ignore=DL3007
FROM alpine:latest AS builder

ARG VERSION

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

# hadolint ignore=DL3018,DL3003,SC2164
RUN \
    apk add --no-cache --virtual .build-deps \
      bash \  
      autoconf \
      automake \
      binutils \
      gcc \
      libnl3-dev \
      #libnftnl-dev \
      #libmnl-dev \
      linux-headers \
      make \
      musl-dev \
      openssl-dev \
      \
      git \
      \
      openssl-libs-static \
      zlib-static \
      libmnl-static \
      libnl3-static \
    ; \
    VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/acassen/keepalived/tags | grep 'name' | cut -d\" -f4 | head -1 )} ; \
    VERSION=${VERSION#v} ; \
    echo "KEEPALIVED_VERSION=${VERSION}" ; \
    git clone --single-branch --branch "v${VERSION}" https://github.com/acassen/keepalived.git keepalived-${VERSION} ; \
    #wget -q https://keepalived.org/software/keepalived-${VERSION}.tar.gz -O keepalived-${VERSION}.tar.gz && tar -zxf keepalived-${VERSION}.tar.gz && rm keepalived-${VERSION}.tar.gz ; \
    mv keepalived-${VERSION}/ keepalived/ ; \
    cd keepalived/ ; \
    # only next line and bash installation/command is bugfix https://github.com/acassen/keepalived/issues/2503#issuecomment-2466298295
    sed -i 's/#include <linux\/if_ether.h>//' keepalived/vrrp/vrrp.c ; \
    ./autogen.sh ; \
    CFLAGS='-static -s' LDFLAGS=-static \
    /bin/bash ./configure ; \
    make && make DESTDIR=/install_root install ; \
    find /install_root ; \
    rm -rf /install_root/usr/share


FROM scratch AS production

ARG VERSION

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Keepalived" \
      org.opencontainers.image.authors="Alexandre Cassen <acassen@linux-vs.org>, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Keepalived is a routing software written in C" \
      org.opencontainers.image.documentation="https://keepalived.org/manpage.html" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/acassen/keepalived"

COPY --from=builder /install_root /

ENTRYPOINT ["/usr/local/sbin/keepalived","--dont-fork","--log-console", "-f","/etc/keepalived/keepalived.conf", "--pid=/keepalived.pid", "--vrrp_pid=/vrrp.pid"]