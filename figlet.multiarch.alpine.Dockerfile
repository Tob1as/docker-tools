# build: docker build --no-cache --progress=plain -t tobi312/tools:figlet -f figlet.multiarch.alpine.Dockerfile .
# hadolint ignore=DL3007
FROM alpine:latest AS production

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="figlet" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      #org.opencontainers.image.version="2.2.5" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="http://www.figlet.org/ | docker run --rm --name figlet -it tobi312/tools:figlet 'Hello :D'" \
      org.opencontainers.image.documentation="http://www.figlet.org/figlet-man.html" \
      org.opencontainers.image.licenses="BSD-3-Clause" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

# hadolint ignore=DL3018
RUN apk --no-cache add figlet figlet-doc \
    ; \
    for fonts in \
        contributed \
        international \
        ms-dos \
        ours \
    ; \
    do \
        wget -qO- http://ftp.figlet.org/pub/figlet/fonts/${fonts}.tar.gz | tar xvz -C /usr/share/figlet/fonts/ \
        ; \
    done

USER nobody

WORKDIR /usr/share/figlet/fonts/

ENTRYPOINT ["figlet"]
CMD ["--help"]