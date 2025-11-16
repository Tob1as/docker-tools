# build: docker build --no-cache --progress=plain --target binary --build-arg NGINX_VERSION=1.29.1 -t tobi312/tools:static-nginx-unprivileged-nginxuser -f static-nginx.unprivileged-nginxuser.Dockerfile .
FROM alpine:latest AS builder

ARG PCRE2_VERSION=10.46
ARG ZLIB_VERSION=1.3.1
ARG OPENSSL_VERSION=3.5.4
ARG NGINX_VERSION=1.29.1

ARG VCS_REF

ENV BUILD_DIR=/usr/src
ENV OUTPUT_DIR=/nginx

LABEL org.opencontainers.image.title="Static NGINX"\
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.description="Static NGINX${NGINX_VERSION:+ ${NGINX_VERSION}} (unprivileged/nginxuser) build with pcre2${PCRE2_VERSION:+-${PCRE2_VERSION}}, zlib${ZLIB_VERSION:+-${ZLIB_VERSION}} and openssl${OPENSSL_VERSION:+-${OPENSSL_VERSION}}" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

SHELL ["/bin/ash", "-euxo", "pipefail", "-c"]

WORKDIR /usr/src

RUN echo ">> Install build packages ..." && \
    apk add --no-cache --virtual .build-deps \
        linux-headers \
        musl-dev \
        \
        ca-certificates \
        wget \
        g++ \
        make \
        perl \
        file \
        tree \
        \
        autoconf \
        automake \
        libtool \
        \
        #geoip-dev geoip-static \
    && \
    mkdir -p ${OUTPUT_DIR}

# https://github.com/maxmind/geoip-api-c
RUN GEOIP1_VERSION=1.6.12 && \
    echo ">> Download and compile: GeoIP V1 ${GEOIP1_VERSION} ..." && \
    wget https://github.com/maxmind/geoip-api-c/archive/refs/tags/v${GEOIP1_VERSION}.tar.gz && \
    tar xf v${GEOIP1_VERSION}.tar.gz && \
    rm v${GEOIP1_VERSION}.tar.gz && \
    cd geoip-api-c-${GEOIP1_VERSION} && \
    ./bootstrap && \
    ./configure --enable-static --disable-shared && \
    make -j$(nproc) && \
    make install && \
    cd ..

# https://github.com/PCRE2Project/pcre2
RUN echo ">> Download: pcre2-${PCRE2_VERSION} ..." && \
    wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz && \
    tar xf pcre2-${PCRE2_VERSION}.tar.gz

# https://github.com/madler/zlib
RUN echo ">> Download: zlib-${ZLIB_VERSION} ..." && \
    wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz && \
    tar xf zlib-${ZLIB_VERSION}.tar.gz 

# https://github.com/openssl/openssl
RUN echo ">> Download: openssl-${OPENSSL_VERSION} ..." && \
    wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz && \
    tar xf openssl-${OPENSSL_VERSION}.tar.gz 

# nginx user
RUN echo 'nginx:x:101:101:nginx:/var/cache/nginx:/sbin/nologin' >> /etc/passwd ; \
    echo 'nginx:x:101:nginx' >> /etc/group
    
# === Build NGINX static ===
# https://github.com/nginx/nginx && https://nginx.org/
# https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#sources
# https://nginx.org/en/docs/configure.html
# configured build like: "docker run --rm --name nginx-info --entrypoint=nginx -it nginx:alpine-slim -V"
RUN echo ">> Download and BUILD: nginx-${NGINX_VERSION} ..." && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar xf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --with-pcre=../pcre2-${PCRE2_VERSION} \
        --with-zlib=../zlib-${ZLIB_VERSION} \
        --with-openssl=../openssl-${OPENSSL_VERSION} \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx  \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf  \
        #--error-log-path=/var/log/nginx/error.log \
        --error-log-path=/dev/stderr \
        #--http-log-path=/var/log/nginx/access.log \
        --http-log-path=/dev/stdout \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
        --user=nginx \
        --group=nginx \
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
        --with-cc-opt='-static -Os -fstack-clash-protection -Wformat -Werror=format-security -fno-plt -g' \
        --with-ld-opt='-static -Wl,--as-needed,-O1,--sort-common' \
        # others:
        --with-http_geoip_module \
    && \
    make -j$(nproc) && \
    strip objs/nginx && \
    cd ..

RUN echo ">> do something after builds ..." && \
    mkdir -p ${OUTPUT_DIR}/etc/nginx/ ${OUTPUT_DIR}/var/cache/nginx/ ${OUTPUT_DIR}/usr/sbin ${OUTPUT_DIR}/usr/lib/nginx/modules ${OUTPUT_DIR}/var/run ${OUTPUT_DIR}/var/log/nginx ${OUTPUT_DIR}/usr/share/nginx/html ${OUTPUT_DIR}/etc/ssl/ && \
    cp nginx-${NGINX_VERSION}/objs/nginx ${OUTPUT_DIR}/usr/sbin/ && \
    cp -r nginx-${NGINX_VERSION}/conf/. ${OUTPUT_DIR}/etc/nginx/ && \
    #cp -r nginx-${NGINX_VERSION}/html/. ${OUTPUT_DIR}/usr/share/nginx/html && \
    mv ${OUTPUT_DIR}/etc/nginx/nginx.conf ${OUTPUT_DIR}/etc/nginx/nginx.conf.bak && \
    file ${OUTPUT_DIR}/usr/sbin/nginx && \
    #ldd ${OUTPUT_DIR}/usr/sbin/nginx && \
    #tree ${OUTPUT_DIR} && \
    ${OUTPUT_DIR}/usr/sbin/nginx -V && \
    ${OUTPUT_DIR}/usr/sbin/nginx -help

COPY <<EOF /nginx/etc/nginx/nginx.conf

#user  nginx;
#user  nginx nginx;
worker_processes  auto;

#error_log  /var/log/nginx/error.log notice;
error_log  /dev/stderr notice;

pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    #access_log  /var/log/nginx/access.log  main;
    access_log  /dev/stdout  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    #server_tokens off;

    include /etc/nginx/conf.d/*.conf;
}

EOF

COPY <<EOF /nginx/etc/nginx/conf.d/default.conf
# HTTP server
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    #charset koi8-r;

    #access_log  /var/log/nginx/access.log  main;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    #error_page  404              /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
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
    #    fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
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

# HTTPS server
#server {
#    listen       443 ssl;
#    listen  [::]:443 ssl;
#    server_name  localhost;
#
#    ssl_certificate      /etc/ssl/ssl.crt;
#    ssl_certificate_key  /etc/ssl/ssl.key;
#
#    ssl_session_cache    shared:SSL:1m;
#    ssl_session_timeout  5m;
#
#    ssl_ciphers  HIGH:!aNULL:!MD5;
#    ssl_prefer_server_ciphers  on;
#
#    #charset koi8-r;
#
#    #access_log  /var/log/nginx/access.log  main;
#
#    location / {
#        root   /usr/share/nginx/html;
#        index  index.html index.htm;
#    }
#
#    #error_page  404              /404.html;
#
#    # redirect server error pages to the static page /50x.html
#    #
#    error_page   500 502 503 504  /50x.html;
#    location = /50x.html {
#        root   /usr/share/nginx/html;
#    }
#
#    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
#    #
#    #location ~ \\.php$ {
#    #    proxy_pass   http://127.0.0.1;
#    #}
#
#    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
#    #
#    #location ~ \\.php$ {
#    #    root           html;
#    #    fastcgi_pass   127.0.0.1:9000;
#    #    fastcgi_index  index.php;
#    #    fastcgi_param  SCRIPT_FILENAME  /scripts\$fastcgi_script_name;
#    #    include        fastcgi_params;
#    #}
#
#    # deny access to .htaccess files, if Apache's document root
#    # concurs with nginx's one
#    #
#    #location ~ /\\.ht {
#    #    deny  all;
#    #}
#
#    location /nginx_status {
#        stub_status on;   
#        access_log off;
#        allow 127.0.0.1;
#        allow 10.0.0.0/8;
#        allow 172.16.0.0/12;
#        allow 192.168.0.0/16;
#        allow ::1;
#        allow fc00::/7;
#        deny all;
#    }
#
#    location = /favicon.ico { log_not_found off; access_log off; }
#    location = /robots.txt { log_not_found off; }
#}

EOF

COPY <<EOF /nginx/usr/share/nginx/html/index.html
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
<a href="https://github.com/Tob1as/docker-tools/blob/main/static-nginx.unprivileged-nginxuser.Dockerfile">https://github.com/Tob1as/docker-tools</a>.</p>

<p><em>Have Fun!</em></p>
</body>
</html>
EOF

RUN tree ${OUTPUT_DIR}

# unprivileged / non-root user (patch)
RUN sed -i -E 's/^(\s*#?\s*listen\s+)(\[::\]:)?80(\b[^0-9])/\1\28080\3/' ${OUTPUT_DIR}/etc/nginx/conf.d/default.conf && \
    sed -i -E 's/^(\s*#?\s*listen\s+)(\[::\]:)?443(\b[^0-9])/\1\28443\3/' ${OUTPUT_DIR}/etc/nginx/conf.d/default.conf && \
    chown -R 101:101 /nginx/


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
      org.opencontainers.image.description="Static NGINX${NGINX_VERSION:+ ${NGINX_VERSION}} (unprivileged/nginxuser) build with pcre2${PCRE2_VERSION:+-${PCRE2_VERSION}}, zlib${ZLIB_VERSION:+-${ZLIB_VERSION}} and openssl${OPENSSL_VERSION:+-${OPENSSL_VERSION}}" \
      org.opencontainers.image.documentation="https://github.com/Tob1as/docker-tools/" \
      org.opencontainers.image.base.name="scratch" \
      org.opencontainers.image.licenses="BSD-2-Clause license" \
      org.opencontainers.image.url="https://hub.docker.com/r/tobi312/tools" \
      org.opencontainers.image.source="https://github.com/Tob1as/docker-tools/"

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /nginx /

COPY <<EOF /etc/passwd
#root:x:0:0:root:/root:/sbin/nologin
nginx:x:101:101:nginx:/var/cache/nginx:/sbin/nologin
EOF

COPY <<EOF /etc/group
#root:x:0:root
nginx:x:101:nginx
EOF

STOPSIGNAL SIGQUIT

# root user
#EXPOSE 80
# unprivileged / non-root user
EXPOSE 8080
USER 101

CMD ["nginx", "-g", "daemon off;"]