# build: docker build --no-cache --progress=plain --target binary --build-arg NGINX_VERSION=1.28.0 -t tobi312/tools:static-nginx-unprivileged -f static-nginx.unprivileged.Dockerfile .
ARG NGINX_VERSION

FROM tobi312/tools:static-nginx${NGINX_VERSION:+-${NGINX_VERSION}} AS base
# based on image from https://github.com/Tob1as/docker-tools/blob/main/static-nginx.Dockerfile
LABEL org.opencontainers.image.title="Static NGINX"\
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"


FROM alpine:latest AS build-unprivileged

LABEL org.opencontainers.image.title="Static NGINX"\
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=base /nginx /nginx

# for unprivileged change port (8080/8443) and set permissions
RUN sed -i -E 's/^(\s*#?\s*listen\s+)(\[::\]:)?80(\b[^0-9])/\1\28080\3/' /nginx/conf/conf.d/default.conf && \
    sed -i -E 's/^(\s*#?\s*listen\s+)(\[::\]:)?443(\b[^0-9])/\1\28443\3/' /nginx/conf/conf.d/default.conf && \
    chown -R 65534:65534 /nginx/


FROM scratch AS binary

ARG VCS_REF
ARG BUILD_DATE

ARG PCRE2_VERSION
ARG ZLIB_VERSION
ARG OPENSSL_VERSION
ARG NGINX_VERSION

LABEL org.opencontainers.image.title="Static NGINX" \
      #org.opencontainers.image.vendor="" \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${NGINX_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static NGINX${NGINX_VERSION:+ ${NGINX_VERSION}} (unprivileged) build with pcre2${PCRE2_VERSION:+-${PCRE2_VERSION}}, zlib${ZLIB_VERSION:+-${ZLIB_VERSION}} and openssl${OPENSSL_VERSION:+-${OPENSSL_VERSION}}" \
      org.opencontainers.image.documentation="https://github.com/Tob1as/docker-tools/" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="BSD-2-Clause license" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=build-unprivileged /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build-unprivileged /nginx /nginx

COPY <<EOF /etc/passwd
nobody:x:65534:65534:nobody:/:/sbin/nologin
EOF

COPY <<EOF /etc/group
nogroup:x:65534:
EOF

STOPSIGNAL SIGQUIT

EXPOSE 8080

USER 65534

ENTRYPOINT ["/nginx/nginx"]
CMD ["-p", "/nginx", "-g", "daemon off;"]