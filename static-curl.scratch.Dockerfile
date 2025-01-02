# build: docker build --no-cache --progress=plain --build-arg CURL_VERSION=8.11.0 -t tobi312/tools:static-curl -f static-curl.scratch.Dockerfile .
FROM alpine:latest AS static-curl

# curl: https://github.com/stunnel/static-curl
# (Alternatives: https://github.com/tarampampam/curl-docker ,  https://github.com/moparisthebest/static-curl or https://github.com/perryflynn/static-binaries)

ARG CURL_VERSION
ARG CURL_LIBC="musl"

RUN \
   set -ex ; \
   apk add --no-cache \
      ca-certificates \
      #curl \
   ; \
   ARCH=`uname -m` ; \
	echo "ARCH=$ARCH" ; \
   if [ "$ARCH" == "x86_64" ]; then \
      echo "x86_64 (amd64)" ; \
      TARGETARCH="$ARCH"; \
   elif [ "$ARCH" == "aarch64" ]; then \
      echo "aarch64 (arm64)" ; \
      TARGETARCH="$ARCH"; \
   elif [ "$ARCH" == "armv7l" ]; then \
      echo "armv7 (arm)" ; \
      TARGETARCH="armv7"; \
   elif [ "$ARCH" == "riscv64" ]; then \
      echo "riscv64" ; \
      TARGETARCH="$ARCH"; \
   elif [ "$ARCH" == "ppc64le" ]; then \
      echo "ppc64le" ; \
      TARGETARCH="powerpc64le"; \
   elif [ "$ARCH" == "s390x" ]; then \
      echo "s390x" ; \
      TARGETARCH="$ARCH"; \
   else \
      echo "unknown arch" ; \
      exit 1; \
   fi ; \
   export TARGETARCH=${TARGETARCH} ; \
   #CURL_VERSION=${CURL_VERSION:-$(curl -s https://api.github.com/repos/stunnel/static-curl/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
   CURL_VERSION=${CURL_VERSION:-$(wget -qO- https://api.github.com/repos/stunnel/static-curl/releases/latest | grep 'tag_name' | cut -d\" -f4)} ; \
   echo "CURL_VERSION=${CURL_VERSION}" ; \
   #curl -sqL https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-${TARGETARCH}-${CURL_LIBC}-${CURL_VERSION}.tar.xz  | tar -xJ -C /usr/local/bin/ curl ; \
   wget -qO- https://github.com/stunnel/static-curl/releases/download/${CURL_VERSION}/curl-linux-${TARGETARCH}-${CURL_LIBC}-${CURL_VERSION}.tar.xz  | tar -xJ -C /usr/local/bin/ curl ; \
   /usr/local/bin/curl --version

FROM scratch

ARG CURL_VERSION
ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="cURL" \
      org.opencontainers.image.authors="cURL Community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${CURL_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static cURL - A command line tool and library for transferring data with URL syntax." \
      org.opencontainers.image.documentation="https://curl.se/" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://github.com/stunnel/static-curl"

COPY --from=static-curl /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=static-curl /usr/local/bin/curl /usr/bin/curl

ENTRYPOINT ["/usr/bin/curl"]
#CMD ["--version"]
#CMD ["--help", "all"]