# build: docker build --no-cache --progress=plain -t tobi312/tools:squid -f squid.alpine.Dockerfile .
# hadolint ignore=DL3007
FROM alpine:latest AS production

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="squid" \
      org.opencontainers.image.authors="Squid Software Foundation, Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${BUILD_DATE}.${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Squid Web Proxy Cache" \
      org.opencontainers.image.documentation="http://www.squid-cache.org/" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="GPL-2.0" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

# hadolint ignore=DL3018
RUN \
    apk add --no-cache \
        squid \
        #acf-squid \
        #squid-doc \
        #squid-lang-de \
        #ca-certificates \
    ; \
    printf "\npid_filename none\n" >> /etc/squid/squid.conf ; \
    mkdir /etc/squid/conf.d/ ; \
    printf "\ninclude /etc/squid/conf.d/*.conf\n" >> /etc/squid/squid.conf ; \
    touch /etc/squid/conf.d/empty.conf ; \
    echo ">> squid installed!"

USER squid
#VOLUME /var/cache/squid
EXPOSE 3128/tcp

ENTRYPOINT ["/usr/sbin/squid"]
CMD ["-f", "/etc/squid/squid.conf", "-NYCd", "1"]