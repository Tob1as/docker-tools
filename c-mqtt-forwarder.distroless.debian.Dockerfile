# docker build --no-cache --progress=plain -t tobi312/tools:c-mqtt-forwarder-distroless -f c-mqtt-forwarder.distroless.debian.Dockerfile .

FROM debian:bookworm-slim AS builder

ARG VERSION=master

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
    apt-get update ; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        #build-essential \
        pkg-config \
        g++ \
        make \
        cmake \
        git \
        libmosquitto-dev \
        uthash-dev \
        libcjson-dev \
        uuid-dev \
    ; \
    rm -rf /var/lib/apt/lists/* ; \
    echo "Build requirements installed!"

WORKDIR /usr/src/

RUN \
    git clone --branch ${VERSION} --single-branch https://git.ypbind.de/repository/c-mqtt-forwarder.git c-mqtt-forwarder
    #wget -qO- https://git.ypbind.de/cgit/c-mqtt-forwarder/snapshot/c-mqtt-forwarder-${VERSION}.tar.gz | tar xzv ; mv c-mqtt-forwarder-${VERSION} c-mqtt-forwarder

WORKDIR /usr/src/c-mqtt-forwarder

RUN cmake . ; \
    make ; \
    make install

COPY <<EOF /etc/mqtt-forwarder/config.json
{
  "in": [
    {
      "host": "mqtt-in-1.example.com",
      "port": 8883,
      "topic": "#",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "user": "mqtt-in-1-user",
      "password": "It's so fluffy I'm gonna DIE!",
      "qos": 0,
      "timeout": 60,
      "keepalive": 5,
      "reconnect_delay": 10
    },
    {
      "host": "mqtt-in-2.example.net",
      "port": 1883,
      "topic": "input/topic/no/+/data",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "ssl_auth_public": "/path/to/client/public.PE",
      "ssl_auth_private": "/path/to/client/private.key",
      "qos": 2,
      "timeout": 180
    }
  ],
  "out": [
    {
      "host": "mqtt-out-1.example.com",
      "port": 8883,
      "topic": "output/topic/1",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "user": "mqtt-out-1-user",
      "password": "SO FLUFFY!",
      "qos": 0,
      "timeout": 60,
      "keepalive": 5
    },
    {
      "host": "mqtt-out-2.example.net",
      "port": 1883,
      "topic": "secondary/output/topic/2",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "ssl_auth_public": "/path/to/client/public.pem",
      "ssl_auth_private": "/path/to/client/private.key",
      "qos": 1,
      "timeout": 180
    },
    {
      "host": "mqtt-out-3.example.com",
      "port": 1884,
      "topic": "path/to/topic",
      "insecure_ssl": true,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "user": "mqtt-out-user",
      "password": "Assemble the minions!",
      "qos": 0,
      "timeout": 60,
      "keepalive": 5
    },
    {
      "host": "mqtt-out-4.example.net",
      "port": 2885,
      "topic": "topic/on/out/4",
      "insecure_ssl": false,
      "ca_file": "/etc/ssl/certs/ca-certificates.crt",
      "ssl_auth_public": "/path/to/client/public.pem",
      "ssl_auth_private": "/path/to/client/private.key",
      "qos": 1
    }
  ]
}
EOF



# Simple example of how to properly extract packages for reuse in distroless
# Taken from: https://github.com/GoogleContainerTools/distroless/issues/863#issuecomment-986062361
# and: https://github.com/fluent/fluent-bit/blob/master/dockerfiles/Dockerfile#L100-L159
FROM debian:bookworm-slim AS deb-extractor

# We download all debs locally then extract them into a directory we can use as the root for distroless.
# We also include some extra handling for the status files that some tooling uses for scanning, etc.
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# List of packages for download separated by spaces.
ENV PACKAGE_LIST="libmosquitto1 libcjson1 libuuid1"

RUN \
    #echo "deb http://deb.debian.org/debian bookworm-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y apt-rdepends tree && \
    # Search subpackages for package (apt-rdepends PACKAGE | grep -v "^ " | sort -u | tr '\n' ' ')
    #packages=$(for package in $PACKAGE_LIST; do \
    #    apt-rdepends $package 2>/dev/null | \
    #    grep -v "^ " | \
    #    grep -v "^PreDepends:" | \
    #    sort -u; \
    #done | sort -u) && \
    packages=$PACKAGE_LIST ; \
    # Download packages
    echo ">> Packages to Download: $(echo $packages | tr '\n' ' ')" && \
    apt-get download \
        $packages \
    && \
    mkdir -p /dpkg/var/lib/dpkg/status.d/ && \
    for deb in *.deb; do \
        package_name=$(dpkg-deb -I "${deb}" | awk '/^ Package: .*$/ {print $2}'); \
        echo "Processing: ${package_name}"; \
        dpkg --ctrl-tarfile "$deb" | tar -Oxf - ./control > "/dpkg/var/lib/dpkg/status.d/${package_name}"; \
        dpkg --extract "$deb" /dpkg || exit 10; \
    done \
    && \
    echo "Packages have been processed !"

# Remove unnecessary files extracted from deb packages like man pages and docs etc.
RUN find /dpkg/ -type d -empty -delete && \
    rm -r /dpkg/usr/share/doc/

# List directory and file structure
RUN tree /dpkg



# We want latest at time of build
# hadolint ignore=DL3006
FROM gcr.io/distroless/cc-debian12:latest AS production

ARG VCS_REF
ARG BUILD_DATE
ARG VERSION
      
LABEL org.opencontainers.image.title="c-mqtt-forwarder" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="MQTT message forwarder to forward MQTT from multiple input brokers to multiple output brokers (fan-in/fan-out)" \
      org.opencontainers.image.documentation="https://ypbind.de/maus/projects/c-mqtt-forwarder/" \
      org.opencontainers.image.base.name="gcr.io/distroless/cc-debian12:latest" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/Tob1as/docker-tools" \
      org.opencontainers.image.source="https://git.ypbind.de/cgit/c-mqtt-forwarder"

# Copy the libraries from the extractor stage into root
COPY --from=deb-extractor /dpkg /

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# binary & example
COPY --from=builder --chown=1000:100 /usr/local/bin/c-mqtt-forwarder /usr/local/bin/c-mqtt-forwarder
COPY --from=builder --chown=1000:100 /etc/mqtt-forwarder/config.json /etc/mqtt-forwarder/config.json

USER nobody

ENTRYPOINT ["c-mqtt-forwarder"]
#CMD ["--help"]
CMD ["--config=/etc/mqtt-forwarder/config.json"]