# build: docker build --no-cache --progress=plain --build-arg PHP_FPM_EXPORTER_VERSION=v2.2.0 -t tobi312/tools:php-fpm-exporter -f php-fpm-exporter.scratch.Dockerfile .
FROM golang:alpine AS builder

ARG PHP_FPM_EXPORTER_VERSION

ENV GOPATH=/go
ENV CGO_ENABLED=0

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

WORKDIR /go/src/php-fpm_exporter

RUN apk update && apk add --no-cache git

RUN PHP_FPM_EXPORTER_VERSION=${PHP_FPM_EXPORTER_VERSION:-$(wget -qO- https://api.github.com/repos/hipages/php-fpm_exporter/releases/latest | grep 'tag_name' | cut -d '"' -f4)} ; \
    echo "PHP_FPM_EXPORTER_VERSION=${PHP_FPM_EXPORTER_VERSION}" ; \
    git clone --branch ${PHP_FPM_EXPORTER_VERSION} --single-branch https://github.com/hipages/php-fpm_exporter.git . ; \
    BUILD_VERSION=$(echo ${PHP_FPM_EXPORTER_VERSION} | sed 's/[^.0-9][^.0-9]*//g') ; \
    VCS_REF=$(git rev-parse HEAD) ; \
    BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') ; \
    rm go.mod go.sum && go mod init github.com/hipages/php-fpm_exporter && go mod tidy ; \
    GOOS="$(go env GOOS)" GOARCH="$(go env GOARCH)" \
    go build -trimpath -a -v -ldflags "-X main.version=${BUILD_VERSION} -X main.commit=${VCS_REF} -X main.date=${BUILD_DATE}" -o "${GOPATH}/bin/php-fpm_exporter" ; \
    ${GOPATH}/bin/php-fpm_exporter version


FROM scratch AS binary

ARG VCS_REF
ARG BUILD_DATE
ARG PHP_FPM_EXPORTER_VERSION

LABEL org.opencontainers.image.title="php-fpm_exporter" \
      org.opencontainers.image.description="A prometheus exporter for PHP-FPM." \
      org.opencontainers.image.authors="Tobias Hargesheimer <docker@ison.ws>" \
      org.opencontainers.image.version="${PHP_FPM_EXPORTER_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.documentation="https://github.com/hipages/php-fpm_exporter" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools"

COPY --from=builder /go/bin/php-fpm_exporter /usr/local/bin/

#ENV PHP_FPM_SCRAPE_URI="tcp://127.0.0.1:9000/status"
#    PHP_FPM_WEB_LISTEN_ADDRESS=":9253" \
#    PHP_FPM_WEB_TELEMETRY_PATH="/metrics" \
#    PHP_FPM_FIX_PROCESS_COUNT="false"
    
EXPOSE     9253

# user: nobody
USER 65534

ENTRYPOINT [ "php-fpm_exporter", "server" ]
#CMD [ "--log.level=info", "--phpfpm.scrape-uri=tcp://127.0.0.1:9000/status",  "--web.listen-address=:9253", "--web.telemetry-path=/metrics", "--phpfpm.fix-process-count=false" ]