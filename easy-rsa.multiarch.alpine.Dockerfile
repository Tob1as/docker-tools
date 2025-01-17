# build: docker build --no-cache --progress=plain -t tobi312/tools:easy-rsa -f easy-rsa.multiarch.alpine.Dockerfile .
# hadolint ignore=DL3007
FROM alpine:latest AS production

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION

ENV EASYRSA_PKI="/easyrsa/pki"

LABEL org.opencontainers.image.title="easy-rsa" \
      org.opencontainers.image.authors="OpenVPN development community, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="easy-rsa is a CLI utility to build and manage a PKI CA." \
      org.opencontainers.image.licenses="GPLv2" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/OpenVPN/easy-rsa"

# hadolint ignore=DL3018
RUN apk --no-cache add \
        bash \
        tzdata \
        openssl \
    ; \
    addgroup --gid 1000 easyrsa ; \
    adduser --system --shell /bin/sh --uid 1000 --ingroup easyrsa --home /easyrsa easyrsa

# hadolint ignore=DL3018
#RUN apk --no-cache add \
#        easy-rsa \
#        easy-rsa-doc \
#    ; \
#    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin/easyrsa

# hadolint ignore=DL3018,SC2086
RUN apk add --no-cache --virtual .build-deps \
        curl \
        ca-certificates \
    ; \
    VERSION=${VERSION:-$(curl -s https://api.github.com/repos/OpenVPN/easy-rsa/releases/latest | grep 'tag_name' | cut -d\" -f4 | tr -d 'v')} ; \
    echo "EASY_RSA_VERSION=${VERSION}" ; \
    EASY_RSA_PATH="/usr/share/easy-rsa" ; \
    mkdir -p "${EASY_RSA_PATH}" ; \
    INSTALL_FILES="EasyRSA-${VERSION}/easyrsa EasyRSA-${VERSION}/openssl-easyrsa.cnf EasyRSA-${VERSION}/vars.example EasyRSA-${VERSION}/x509-types" ; \
    curl -sL  "https://github.com/OpenVPN/easy-rsa/releases/download/v${VERSION}/EasyRSA-${VERSION}.tgz" | tar xfz - --strip-components=1 $INSTALL_FILES -C "${EASY_RSA_PATH}" ; \
    ln -s "${EASY_RSA_PATH}/easyrsa" /usr/local/bin/easyrsa ; \
    apk del --no-network --purge .build-deps
	
USER easyrsa
WORKDIR /easyrsa
VOLUME /easyrsa

ENTRYPOINT ["easyrsa"]
CMD ["help"]