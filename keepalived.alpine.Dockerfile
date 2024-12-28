# docker build --no-cache --progress=plain --build-arg VERSION=v2.3.1 -t tobi312/tools:keepalived-alpine -f keepalived.alpine.Dockerfile .
# hadolint ignore=DL3007
FROM alpine:latest AS production

ARG VERSION

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Keepalived" \
      org.opencontainers.image.authors="Alexandre Cassen <acassen@linux-vs.org>, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Keepalived is a routing software written in C" \
      org.opencontainers.image.documentation="https://keepalived.org/manpage.html" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/acassen/keepalived"

# hadolint ignore=DL3018,DL3003,SC2103
RUN \
    apk add --no-cache --virtual .build-deps \
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
    ; \
    apk add --no-cache \
      musl \  
      libnl3 \
    ; \
    VERSION=${VERSION:-$(wget -qO- https://api.github.com/repos/acassen/keepalived/tags | grep 'name' | cut -d\" -f4 | head -1 )} ; \
    VERSION=${VERSION#v} ; \
    echo "KEEPALIVED_VERSION=${VERSION}" ; \
    git clone --single-branch --branch "v${VERSION}" https://github.com/acassen/keepalived.git keepalived-${VERSION} ; \
    #wget -q https://keepalived.org/software/keepalived-${VERSION}.tar.gz -O keepalived-${VERSION}.tar.gz && tar -zxf keepalived-${VERSION}.tar.gz && rm keepalived-${VERSION}.tar.gz ; \
    mv keepalived-${VERSION}/ keepalived/ ; \
    cd keepalived/ ; \
    ./autogen.sh ; \
    ./configure ; \
    make && make install ; \
    strip /usr/local/sbin/keepalived ; \
    cd .. ; \
    rm -r keepalived/ ; \
    apk del --no-network --purge .build-deps
    
ENTRYPOINT ["/usr/local/sbin/keepalived","--dont-fork","--log-console", "-f","/etc/keepalived/keepalived.conf"]