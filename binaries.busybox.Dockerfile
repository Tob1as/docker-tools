# Use this Dockerfile/Image to copy static files from Images to localhost:
# 1. build: docker build --no-cache --progress=plain -t tobi312/tools:binaries -f binaries.busybox.Dockerfile .
# 2. run:   docker run --rm --name binaries-copy -d docker.io/tobi312/tools:binaries
# 3. copy:  docker cp binaries-copy:/binaries ./binaries
# 4. clean: docker rm -fv binaries-copy
FROM busybox:stable

RUN mkdir /binaries
WORKDIR /binaries

COPY --from=docker.io/library/alpine:latest /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# from scratch images
COPY --from=tobi312/tools:azcopy /usr/local/bin/azcopy .
COPY --from=tobi312/tools:keepalived /usr/local/sbin/keepalived .
COPY --from=tobi312/tools:mqtt-forwarder /usr/local/bin/mqtt-forwarder .
COPY --from=tobi312/tools:postgres-exporter /bin/postgres_exporter .
COPY --from=tobi312/tools:proxyscotch /usr/local/bin/proxyscotch .
COPY --from=tobi312/tools:static-curl /usr/bin/curl .
COPY --from=tobi312/tools:static-helm /usr/local/bin/helm .
COPY --from=tobi312/tools:static-jq /usr/local/bin/jq .
COPY --from=tobi312/tools:static-kubectl /usr/local/bin/kubectl .
COPY --from=tobi312/tools:static-nginx /nginx/ ./nginx/
COPY --from=tobi312/tools:static-ssh-tools /usr/local/bin/ ./ssh-tools/
COPY --from=tobi312/tools:static-xq /usr/local/bin/xq .
COPY --from=tobi312/tools:static-yq /usr/local/bin/yq .
#COPY --from=tobi312/tools:static-envsubst /usr/local/bin/envsubst .

# from distroless images (has additional dependencies)
COPY --from=tobi312/tools:prometheus-mosquitto-exporter /usr/local/bin/prometheus-mosquitto-exporter .
COPY --from=tobi312/tools:prometheus-mqtt-transport /usr/local/bin/ ./prom2mqtt/

RUN tree .

#ENTRYPOINT [""]
CMD ["sleep", "infinity"]