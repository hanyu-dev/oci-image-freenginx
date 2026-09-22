ARG ALPINE_BASE_VERSION=3.24.1
ARG ALPINE_BASE_HASH=28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

ARG UID=65532
ARG GID=65532

FROM docker.io/library/alpine:${ALPINE_BASE_VERSION}@sha256:${ALPINE_BASE_HASH} AS downloader

RUN <<'EOF'
set -e
apk add --no-cache ca-certificates=20260909-r0
apk add --no-cache git=2.54.0-r0
rm -rf /var/lib/apk/tmp/* /var/cache/apk/* /var/log/apk.log
EOF

# === source code: PCRE2Project/pcre2 ===

WORKDIR /src

ARG IMAGE_DEP_PCRE_VERSION

RUN git clone \
    --depth 1 \
    --recurse-submodules \
    --shallow-submodules \
    -j8 \
    --single-branch \
    -b "pcre2-${IMAGE_DEP_PCRE_VERSION}" \
    https://github.com/PCRE2Project/pcre2

WORKDIR /src/pcre2

ARG IMAGE_DEP_PCRE_COMMIT

RUN git checkout "${IMAGE_DEP_PCRE_COMMIT}"

# === source code: zlib-ng/zlib-ng ===

WORKDIR /src

ARG IMAGE_DEP_ZLIB_NG_VERSION

RUN git clone \
    --depth 1 \
    --recurse-submodules \
    --shallow-submodules \
    -j8 \
    --single-branch \
    -b "$IMAGE_DEP_ZLIB_NG_VERSION" \
    https://github.com/zlib-ng/zlib-ng

ARG IMAGE_DEP_ZLIB_NG_COMMIT

WORKDIR /src/zlib-ng

RUN git checkout "${IMAGE_DEP_ZLIB_NG_COMMIT}"

WORKDIR /src/zlib-ng

# === source code: openssl/openssl ===

WORKDIR /src

ARG IMAGE_DEP_OPENSSL_VERSION

RUN git clone \
	--depth 1 \
	--recurse-submodules \
	--shallow-submodules \
	-j8 \
	--single-branch \
	-b "openssl-${IMAGE_DEP_OPENSSL_VERSION}" \
    https://github.com/openssl/openssl

WORKDIR /src/openssl

ARG IMAGE_DEP_OPENSSL_COMMIT

RUN git checkout "${IMAGE_DEP_OPENSSL_COMMIT}"

# == source code: microsoft/mimalloc ===

WORKDIR /src

ARG IMAGE_DEP_MIMALLOC_VERSION

RUN git clone \
    --depth 1 \
    --recurse-submodules \
    --shallow-submodules \
    -j8 \
    --single-branch \
    -b "v$IMAGE_DEP_MIMALLOC_VERSION" \
    https://github.com/microsoft/mimalloc

WORKDIR /src/mimalloc

ARG IMAGE_DEP_MIMALLOC_COMMIT

RUN git checkout "${IMAGE_DEP_MIMALLOC_COMMIT}"

# === source code: google/ngx_brotli ===

WORKDIR /src

RUN git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli ngx-brotli

WORKDIR /src/ngx-brotli

ARG IMAGE_DEP_NGX_BROTLI_COMMIT

RUN git checkout "${IMAGE_DEP_NGX_BROTLI_COMMIT}"

# === source code: aperezdc/ngx-fancyindex ===

WORKDIR /src

ARG IMAGE_DEP_NGX_FANCYINDEX_VERSION

RUN git clone \
    --depth 1 \
    --recurse-submodules \
    --shallow-submodules \
    -j8 \
    --single-branch \
    -b "v$IMAGE_DEP_NGX_FANCYINDEX_VERSION" \
    https://github.com/aperezdc/ngx-fancyindex

WORKDIR /src/ngx-fancyindex

ARG IMAGE_DEP_NGX_FANCYINDEX_COMMIT

RUN git checkout "${IMAGE_DEP_NGX_FANCYINDEX_COMMIT}"

# === source code: freenginx/nginx ===

WORKDIR /src

ARG IMAGE_FREENGINX_VERSION

RUN git clone \
    --depth 1 \
    --recurse-submodules \
    --shallow-submodules \
    -j8 \
    --single-branch \
    -b "release-${IMAGE_FREENGINX_VERSION}" \
    https://github.com/freenginx/nginx

ARG IMAGE_FREENGINX_COMMIT

WORKDIR /src/nginx

RUN git checkout "${IMAGE_FREENGINX_COMMIT}"

WORKDIR /src/nginx

# === patches ===

WORKDIR /src/nginx

COPY ./patches/freenginx ./patches

RUN git apply --whitespace=nowarn ./patches/*.patch

FROM docker.io/library/alpine:${ALPINE_BASE_VERSION}@sha256:${ALPINE_BASE_HASH} AS builder

RUN <<'EOF'
set -e
apk add --no-cache build-base=0.5-r4
apk add --no-cache cmake=4.2.3-r0
apk add --no-cache perl-dev=5.42.2-r0
apk add --no-cache linux-headers=7.0.0-r1
rm -rf /var/lib/apk/tmp/* /var/cache/apk/* /var/log/apk.log
EOF

COPY --from=downloader /src /src

ARG SOURCE_DATE_EPOCH
ENV SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH}

# === install: zlib-ng ===

WORKDIR /src/zlib-ng

RUN <<'EOF'
set -e
./configure --zlib-compat --static
make -j "$(nproc)"
make install
EOF

# === install: mimalloc ===

# WORKDIR /src/mimalloc
#
# RUN <<'EOF'
# set -e
# cmake -S . -B out/release \
#     -DCMAKE_BUILD_TYPE=Release \
#     -DCMAKE_INSTALL_PREFIX=/usr/local \
#     -DCMAKE_INSTALL_LIBDIR=lib \
#     -DMI_INSTALL_TOPLEVEL=ON \
#     -DMI_BUILD_STATIC=ON \
#     -DMI_BUILD_SHARED=OFF \
#     -DMI_BUILD_TESTS=OFF \
#     -DMI_OVERRIDE=ON \
#     -DMI_OPT_ARCH=ON \
#     -DMI_ALLOW_THP=FULL
# cmake --build out/release -j "$(nproc)"
# cmake --install out/release
# EOF

# === build: ngx-brotli ===

WORKDIR /src/ngx-brotli

RUN <<'EOF'
set -e
mkdir -p ./deps/brotli/out
cmake \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS="-m64 -march=x86-64-v3 -mtune=generic -O3 -march=x86-64-v3 -mtune=generic -flto=auto -fPIC -ffunction-sections -fdata-sections -fstack-protector-strong -fstack-clash-protection -fcf-protection=full -ftrivial-auto-var-init=zero -D_FORTIFY_SOURCE=2" \
	-DCMAKE_CXX_FLAGS="-m64 -march=x86-64-v3 -mtune=generic -O3 -march=x86-64-v3 -mtune=generic -flto=auto -fPIC -ffunction-sections -fdata-sections -fstack-protector-strong -fstack-clash-protection -fcf-protection=full -ftrivial-auto-var-init=zero -D_FORTIFY_SOURCE=2" \
	-DCMAKE_INSTALL_PREFIX=./installed \
	-DBUILD_SHARED_LIBS=OFF \
	-B ./deps/brotli/out \
	-S ./deps/brotli
cmake --build ./deps/brotli/out --config Release --target brotlienc --parallel "$(nproc)"
EOF

# === build: freenginx ===

WORKDIR /src/nginx

RUN <<'EOF'
set -e
./auto/configure \
	--prefix="/opt/freenginx" \
	--pid-path="/opt/freenginx/temp/nginx.pid" \
	--lock-path="/opt/freenginx/temp/nginx.lock" \
	--http-client-body-temp-path="/opt/freenginx/temp/http-client-body" \
	--http-proxy-temp-path="/opt/freenginx/temp/http-proxy" \
	--http-fastcgi-temp-path="/opt/freenginx/temp/http-fastcgi" \
	--http-uwsgi-temp-path="/opt/freenginx/temp/http-uwsgi" \
	--http-scgi-temp-path="/opt/freenginx/temp/http-scgi" \
	--with-openssl="/src/openssl" \
    --with-openssl-opt="no-apps no-shared no-tls1 no-tls1_1 enable-ec_nistp_64_gcc_128 enable-ktls -O3 -march=x86-64-v3 -mtune=generic -flto=auto -fPIC -ffunction-sections -fdata-sections -fstack-protector-strong -fstack-clash-protection -fcf-protection=full -ftrivial-auto-var-init=zero -D_FORTIFY_SOURCE=2" \
	--with-pcre="/src/pcre2" \
	--with-pcre-jit \
	--with-cc-opt="-I/usr/local/include -O3 -march=x86-64-v3 -mtune=generic -flto=auto -ffunction-sections -fdata-sections -fPIE -fstack-protector-strong -fstack-clash-protection -fcf-protection=full -ftrivial-auto-var-init=zero -D_FORTIFY_SOURCE=2" \
	--with-ld-opt="-L/usr/local/lib -static-pie -static-libgcc -flto=auto -lz -Wl,--gc-sections -Wl,-z,noexecstack -Wl,-z,text -Wl,-z,relro -Wl,-z,now" \
	--with-compat \
	--with-threads \
	--with-http_realip_module \
	--with-http_stub_status_module \
	--with-http_ssl_module \
	--with-http_v2_module \
	--with-http_v3_module \
	--with-http_gzip_static_module \
	--with-stream \
	--with-stream_realip_module \
	--with-stream_ssl_module \
	--with-stream_ssl_preread_module \
	--without-stream_split_clients_module \
	--without-stream_set_module \
	--without-http_geo_module \
	--without-http_scgi_module \
	--without-http_uwsgi_module \
	--without-http_split_clients_module \
	--without-http_memcached_module \
	--without-http_ssi_module \
	--without-http_empty_gif_module \
	--without-http_browser_module \
	--without-http_userid_module \
	--without-http_mirror_module \
	--without-http_referer_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--add-module="/src/ngx-brotli" \
	--add-module="/src/ngx-fancyindex"
make -j "$(nproc)"
make install
make clean
EOF

RUN strip --strip-all /opt/freenginx/sbin/nginx

RUN mkdir -p /opt/freenginx/temp

FROM scratch

ARG IMAGE_VCS_DATE
ARG IMAGE_VCS_REV
ARG IMAGE_BUILD_REVISION

ARG IMAGE_FREENGINX_VERSION

LABEL org.opencontainers.image.title="freenginx" \
    org.opencontainers.image.vendor="Hantong Chen" \
    org.opencontainers.image.authors="Hantong Chen" \
    org.opencontainers.image.description="Third-party rootless reproducible OCI image of [freenginx](https://github.com/freenginx/nginx)." \
    org.opencontainers.image.documentation="https://github.com/hanyu-dev/oci-image-freenginx/blob/main/README.md" \
    org.opencontainers.image.source="https://github.com/hanyu-dev/oci-image-freenginx" \
    org.opencontainers.image.url="https://github.com/hanyu-dev/oci-image-freenginx" \
    org.opencontainers.image.licenses="BSD-2-Clause" \
    org.opencontainers.image.created=${IMAGE_VCS_DATE} \
    org.opencontainers.image.version=${IMAGE_FREENGINX_VERSION}-r${IMAGE_BUILD_REVISION} \
    org.opencontainers.image.revision=${IMAGE_VCS_REV}

ARG UID
ARG GID

COPY --from=builder --chown="${UID}:${GID}" --chmod=775 /opt/freenginx /opt/freenginx

COPY --chown="${UID}:${GID}" --chmod=775 ./assets/build/conf /opt/freenginx/conf
COPY --chown="${UID}:${GID}" --chmod=775 ./assets/build/ssl /opt/freenginx/ssl

COPY --from=downloader /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENV SSL_CERT_DIR=/etc/ssl/certs \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=2 \
    CMD ["/opt/freenginx/sbin/nginx", "-qt"]

STOPSIGNAL SIGQUIT

USER "${UID}:${GID}"

ENTRYPOINT ["/opt/freenginx/sbin/nginx", "-g", "daemon off;"]
