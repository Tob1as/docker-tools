# build: docker build --no-cache --progress=plain --target binary -t tobi312/tools:static-nginx -f static-nginx.Dockerfile .
FROM alpine:latest AS builder

ARG PCRE2_VERSION=10.45
ARG ZLIB_VERSION=1.3.1
ARG OPENSSL_VERSION=3.5.0
ARG NGINX_VERSION=1.28.0

ARG VCS_REF

ENV BUILD_DIR=/usr/src
ENV OUTPUT_DIR=/nginx

LABEL org.opencontainers.image.title="Static NGINX"\
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static NGINX ${NGINX_VERSION} build with pcre2-${PCRE2_VERSION}, zlib-${ZLIB_VERSION} and openssl-${OPENSSL_VERSION}" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

WORKDIR /usr/src

RUN echo ">> Install build packages ..." && \
    apk add --no-cache \
        build-base \
        musl-dev \
        wget \
        perl \
        coreutils \
        linux-headers \
        bash \
        libtool \
        autoconf \
        automake \
    && \
    mkdir -p ${OUTPUT_DIR}

# https://github.com/PCRE2Project/pcre2
RUN echo ">> Download: pcre2-${PCRE2_VERSION} ..." && \
    wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz && \
    tar xf pcre2-${PCRE2_VERSION}.tar.gz && \
    cd pcre2-${PCRE2_VERSION} && \
    #./configure --disable-shared --enable-static && \
    #make -j$(nproc) && \
    cd ..

# https://github.com/madler/zlib
RUN echo ">> Download: zlib-${ZLIB_VERSION} ..." && \
    wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar xf zlib-${ZLIB_VERSION}.tar.gz && \
    cd zlib-${ZLIB_VERSION} && \
    #./configure --static && \
    #make -j$(nproc) && \
    cd ..

# https://github.com/openssl/openssl
RUN echo ">> Download: openssl-${OPENSSL_VERSION} ..." && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xf openssl-${OPENSSL_VERSION}.tar.gz && \
    cd openssl-${OPENSSL_VERSION} && \
    #./Configure no-shared no-dso no-tests --prefix="${BUILD_DIR}/openssl-static" && \
    #make -j$(nproc) && \
    #make install_sw && \
    cd ..

# === Build NGINX static ===
# https://github.com/nginx/nginx && https://nginx.org/
# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#compiling-and-installing-from-source
# configured like: "docker run --rm --name nginx-info --entrypoint=nginx -it nginx:alpine -V"
RUN echo ">> Download and BUILD: nginx-${NGINX_VERSION} ..." && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --with-pcre=../pcre2-${PCRE2_VERSION} \
        --with-zlib=../zlib-${ZLIB_VERSION} \
        --with-openssl=../openssl-${OPENSSL_VERSION} \
        --prefix=. \
        #--sbin-path=./nginx \
        --modules-path=./modules \
        #--conf-path=./conf/nginx.conf \
        #--error-log-path=./logs/error.log \
        #--error-log-path=/dev/stderr \
        #--http-log-path=./logs/access.log \
        #--http-log-path=/dev/stdout \
        --pid-path=./run/nginx.pid \
        --lock-path=./run/nginx.lock \
        --http-client-body-temp-path=./temp/client-body \
        --http-proxy-temp-path=./temp/proxy \
        --http-fastcgi-temp-path=./temp/fastcgi \
        --http-uwsgi-temp-path=./temp/uwsgi \
        --http-scgi-temp-path=./temp/scgi \
        #--with-perl_modules_path=./modules_perl \
        --user=nobody \
        --group=nogroup \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-http_v3_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-cc-opt="-static -Os" \
        #--with-cc-opt='-static -Os -fstack-clash-protection -Wformat -Werror=format-security -fno-plt -g' \
        --with-ld-opt="-static" \
        #--with-ld-opt='-static,-Wl,--as-needed,-O1,--sort-common -Wl,-z,pack-relative-relocs' \
    && \
    make -j$(nproc) && \
    strip objs/nginx && \
    cd ..

RUN echo ">> do something after builds ..." && \
    cp nginx-${NGINX_VERSION}/objs/nginx ${OUTPUT_DIR}/ && \
    cp -r nginx-${NGINX_VERSION}/conf ${OUTPUT_DIR}/ && \
    mkdir -p ${OUTPUT_DIR}/logs ${OUTPUT_DIR}/html ${OUTPUT_DIR}/conf/conf.d ${OUTPUT_DIR}/run ${OUTPUT_DIR}/temp ${OUTPUT_DIR}/modules && \
    mv ${OUTPUT_DIR}/conf/nginx.conf ${OUTPUT_DIR}/conf/nginx.conf.bak && \
    file ${OUTPUT_DIR}/nginx && \
    #ldd ${OUTPUT_DIR}/nginx && \
    tree ${OUTPUT_DIR} && \
    ${OUTPUT_DIR}/nginx -V && \
    ${OUTPUT_DIR}/nginx -help

COPY <<EOF /nginx/conf/nginx.conf

#user  nobody;
#user  nobody nogroup;
worker_processes  auto;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;
error_log  /dev/stderr notice;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  logs/access.log  main;
    access_log  /dev/stdout  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include conf.d/*.conf;
}

EOF

COPY <<EOF /nginx/conf/conf.d/default.conf
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    #charset koi8-r;

    #access_log  logs/host.access.log  main;

    location / {
        root   html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }

    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    #
    #location ~ \\.php$ {
    #    proxy_pass   http://127.0.0.1;
    #}

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    #
    #location ~ \\.php$ {
    #    root           html;
    #    fastcgi_pass   127.0.0.1:9000;
    #    fastcgi_index  index.php;
    #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
    #    include        fastcgi_params;
    #}

    # deny access to .htaccess files, if Apache's document root
    # concurs with nginx's one
    #
    #location ~ /\\.ht {
    #    deny  all;
    #}

    location /nginx_status {
        stub_status on;   
        access_log off;
        allow 127.0.0.1;
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        allow ::1;
        allow fc00::/7;
        deny all;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt { log_not_found off; }
}


# another virtual host using mix of IP-, name-, and port-based configuration
#
#server {
#    listen       8000;
#    listen       somename:8080;
#    server_name  somename  alias  another.alias;

#    location / {
#        root   html;
#        index  index.html index.htm;
#    }
#}


# HTTPS server
#
#server {
#    listen       443 ssl;
#    server_name  localhost;

#    ssl_certificate      cert.pem;
#    ssl_certificate_key  cert.key;

#    ssl_session_cache    shared:SSL:1m;
#    ssl_session_timeout  5m;

#    ssl_ciphers  HIGH:!aNULL:!MD5;
#    ssl_prefer_server_ciphers  on;

#    location / {
#        root   html;
#        index  index.html index.htm;
#    }
#}

EOF

COPY <<EOF /nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is working. 
Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
This is a static nginx build, for more details see:
<a href="https://github.com/Tob1as/docker-tools/blob/main/static-nginx.Dockerfile">https://github.com/Tob1as/docker-tools</a>.</p>

<p><em>Have Fun!</em></p>
</body>
</html>
EOF


#FROM busybox:stable AS binary
#FROM gcr.io/distroless/static-debian12:latest AS binary
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
      org.opencontainers.image.description="Static NGINX ${NGINX_VERSION} build with pcre2-${PCRE2_VERSION}, zlib-${ZLIB_VERSION} and openssl-${OPENSSL_VERSION}" \
      org.opencontainers.image.documentation="https://github.com/Tob1as/docker-tools/" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="WTFPL" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /nginx /nginx

COPY <<EOF /etc/passwd
root:x:0:0:root:/root:/sbin/nologin
nobody:x:65534:65534:nobody:/:/sbin/nologin
EOF

COPY <<EOF /etc/group
root:x:0:root
nogroup:x:65534:
EOF

STOPSIGNAL SIGQUIT

EXPOSE 80

ENTRYPOINT ["/nginx/nginx"]
CMD ["-p", "/nginx", "-g", "daemon off;"]