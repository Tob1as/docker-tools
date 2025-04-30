# build: docker build --no-cache --progress=plain --target binary -t tobi312/tools:static-nginx -f static-nginx.Dockerfile .
FROM alpine:latest AS builder

ARG PCRE2_VERSION=10.45
ARG ZLIB_VERSION=1.3.1
ARG OPENSSL_VERSION=3.5.0
ARG NGINX_VERSION=1.28.0

ARG VCS_REF

ENV BUILD_DIR=/usr/src
ENV OUTPUT_DIR=/nginx

LABEL org.opencontainers.image.title="Static NGINX"\
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

WORKDIR /usr/src

RUN apk add --no-cache \
    build-base \
    musl-dev \
    wget \
    perl \
    coreutils \
    linux-headers \
    bash \
    libtool \
    autoconf \
    automake \
    && \
    mkdir -p ${OUTPUT_DIR}

# https://github.com/PCRE2Project/pcre2
RUN wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz && \
    tar xf pcre2-${PCRE2_VERSION}.tar.gz && \
    cd pcre2-${PCRE2_VERSION} && \
    ./configure --disable-shared --enable-static && \
    make -j$(nproc) && \
    cd ..

# https://github.com/madler/zlib
RUN wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar xf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    ./configure --static && \
    make -j$(nproc) && \
    cd ..

# https://github.com/openssl/openssl
RUN wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    ./Configure no-shared no-dso no-tests --prefix="${BUILD_DIR}/openssl-static" && \
    make -j$(nproc) && \
    make install_sw && \
    cd ..

# === Build NGINX static ===
# https://github.com/nginx/nginx && https://nginx.org/
# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#compiling-and-installing-from-source
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
    --prefix=. \
    --with-cc-opt="-static -Os" \
    --with-ld-opt="-static" \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-pcre=../pcre2-${PCRE2_VERSION} \
    --with-zlib=../zlib-${ZLIB_VERSION} \
    --with-openssl=../openssl-${OPENSSL_VERSION} \
    && \
    make -j1 && \
    cd ..

RUN \
    cp nginx-${NGINX_VERSION}/objs/nginx ${OUTPUT_DIR}/ && \
    cp -r nginx-${NGINX_VERSION}/conf ${OUTPUT_DIR}/ && \
    mkdir -p ${OUTPUT_DIR}/logs ${OUTPUT_DIR}/html ${OUTPUT_DIR}/conf/conf.d && \
    echo "<h1>Hello from statically linked nginx!</h1>" > "${OUTPUT_DIR}/html/index.html" && \
    file ${OUTPUT_DIR}/nginx && \
    #ldd ${OUTPUT_DIR}/nginx && \
    tree ${OUTPUT_DIR}

#FROM busybox:stable AS binary
#FROM gcr.io/distroless/static-debian12:latest AS binary
FROM scratch AS binary

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="Static NGINX" \
      #org.opencontainers.image.vendor="" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static NGINX" \
      org.opencontainers.image.documentation="https://github.com/Tob1as/docker-tools/" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="WTFPL" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /nginx /nginx

COPY <<EOF /etc/passwd
root:x:0:0:root:/root:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/:/sbin/nologin
EOF

COPY <<EOF /etc/group
root:x:0:root
nobody:x:65534:
EOF

STOPSIGNAL SIGQUIT

EXPOSE 80

ENTRYPOINT ["/nginx/nginx"]
CMD ["-p", "/nginx", "-g", "daemon off;"]