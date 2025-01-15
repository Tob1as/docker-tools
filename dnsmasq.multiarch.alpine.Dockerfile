# build: docker build --no-cache --progress=plain -t tobi312/tools:dnsmasq -f dnsmasq.multiarch.alpine.Dockerfile .
FROM alpine:latest AS production

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="dnsmasq" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${BUILD_DATE}.${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="dnsmasq: lightweight dns and dhcp" \
      org.opencontainers.image.documentation="https://thekelleys.org.uk/dnsmasq/doc.html" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

RUN apk add --no-cache \
        tzdata \
        #dnsmasq \
        dnsmasq-dnssec \
    ; \
    sed -i 's/#user=.*/user=dnsmasq/g' /etc/dnsmasq.conf ; \
    sed -i 's/#group=.*/group=dnsmasq/g' /etc/dnsmasq.conf

VOLUME [ "/etc/dnsmasq.d/" ]

EXPOSE 53/tcp 53/udp 853/tcp 853/udp 67/udp 68/udp 547/udp 546/udp 69/udp

ENTRYPOINT ["/usr/sbin/dnsmasq", "--keep-in-foreground", "--log-queries=extra", "--log-facility=-", "--conf-file=/etc/dnsmasq.conf" ]
