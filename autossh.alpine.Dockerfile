# build: docker build --no-cache --progress=plain -t tobi312/tools:autossh -f autossh.alpine.Dockerfile .
FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="AutoSSH" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${BUILD_DATE}.${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="AutoSSH: Automatically restart SSH sessions and tunnels." \
      org.opencontainers.image.documentation="https://www.harding.motd.ca/autossh/ , https://github.com/Autossh/autossh" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"
	  
ENV \
    AUTOSSH_PIDFILE=/tmp/autossh.pid \
    AUTOSSH_POLL=30 \
    AUTOSSH_GATETIME=30 \
    AUTOSSH_FIRST_POLL=30 \
    AUTOSSH_LOGLEVEL=0 \
    AUTOSSH_LOGFILE=/dev/stdout

RUN \
    apk --no-cache add \
    autossh \
    openssh-client
	
#USER nobody

ENTRYPOINT ["/bin/sh", "-c"]
#CMD ["/usr/bin/autossh -V"]