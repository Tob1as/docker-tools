# build: docker build --no-cache --progress=plain -t tobi312/tools:autossh -f autossh.alpine.Dockerfile .
# hadolint ignore=DL3007
FROM alpine:latest AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION="${BUILD_DATE}.${VCS_REF}"

LABEL org.opencontainers.image.title="AutoSSH" \
      #org.opencontainers.image.authors="" \
      org.opencontainers.image.version="$VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="AutoSSH: Automatically restart SSH sessions and tunnels." \
      org.opencontainers.image.documentation="https://www.harding.motd.ca/autossh/" \
      org.opencontainers.image.base.name="docker.io/library/alpine:latest" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"
	  
ENV \
    # how long must an ssh session be established before we decide it really was established (in seconds). Default is 30 seconds; use of -f flag sets this to 0.
    #AUTOSSH_GATETIME=30 \
    # file to log to (default is to use the syslog facility)
    AUTOSSH_LOGFILE=/dev/stdout \
    # level of log verbosity (like syslog 0-7)
    AUTOSSH_LOGLEVEL=0 \
    # set the maximum time to live (seconds)
    #AUTOSSH_MAXLIFETIME=86400 \
    # max times to restart (default is no limit)
    #AUTOSSH_MAXSTART=-1 \
    # message to append to echo string (max 64 bytes)
    #AUTOSSH_MESSAGE="SSH Tunnel" \
    # path to ssh if not default
    AUTOSSH_PATH=/usr/bin/ssh \
    # write pid to this file
    AUTOSSH_PIDFILE=/tmp/autossh.pid \
    # how often to check the connection (seconds)
    #AUTOSSH_POLL=600 \
    # time before first connection check (seconds)
    #AUTOSSH_FIRST_POLL=600 \
    # port to use for monitor connection
    #AUTOSSH_PORT=0 \
    # turn logging to maximum verbosity and log to stderr
    #AUTOSSH_DEBUG=0 \
    # BIND_IP
    SSH_BIND_IP="0.0.0.0"
    

# hadolint ignore=DL3018
RUN apk --no-cache add \
        autossh \
        openssh-client \
        sshpass \
    ; \
    mkdir /.ssh && chown nobody:nobody /.ssh && chmod 700 /.ssh

# User: nobody (65534)
USER nobody

ENTRYPOINT ["/usr/bin/autossh"]
#CMD ["--help"]