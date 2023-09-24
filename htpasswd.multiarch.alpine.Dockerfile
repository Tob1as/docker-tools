# build: docker build --no-cache --progress=plain -t tobi312/tools:htpasswd -f htpasswd.multiarch.alpine.Dockerfile .

FROM alpine:latest as builder
RUN apk add --no-cache apache2-utils


FROM alpine:latest

SHELL ["/bin/sh", "-euxo", "pipefail", "-c"]

ARG VCS_REF
ARG BUILD_DATE

LABEL org.opencontainers.image.title="htpasswd" \
	org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
	#org.opencontainers.image.version="${BUILD_DATE}.${VCS_REF}" \
	org.opencontainers.image.created="${BUILD_DATE}" \
	org.opencontainers.image.revision="${VCS_REF}" \
	org.opencontainers.image.description="https://httpd.apache.org/docs/2.4/programs/htpasswd.html | docker run --rm --name htpasswd -it tobi312/tools:htpasswd -bn username passw0rd" \
	org.opencontainers.image.licenses="Apache-2.0" \
	org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
	org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

COPY --from=builder /usr/bin/htpasswd /usr/bin/htpasswd

RUN apk add --no-cache apr-util

USER nobody

ENTRYPOINT ["htpasswd"]
CMD ["--help"]