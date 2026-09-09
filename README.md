# oci-image-freenginx

Third-party rootless reproducible OCI image of [freenginx](https://github.com/freenginx/nginx/).

## Notes

The OCI image requires an x86-64-v3 compatible CPU.

## Reproducibility

To verify the reproducibility of the build, you can use the following command to build the image locally and compare the digest with the one published on GitHub Container Registry (ghcr.io).

```bash
export IMAGE_NAME=hanyu-dev/oci-image-freenginx
export IMAGE_REGISTRY=ghcr.io

# See .github/workflows/build-image.yaml
export IMAGE_DEP_PCRE_VERSION=
export IMAGE_DEP_PCRE_COMMIT=
export IMAGE_DEP_ZLIB_NG_VERSION=
export IMAGE_DEP_ZLIB_NG_COMMIT=
export IMAGE_DEP_OPENSSL_VERSION=
export IMAGE_DEP_OPENSSL_COMMIT=
export IMAGE_DEP_MIMALLOC_VERSION=
export IMAGE_DEP_MIMALLOC_COMMIT=
export IMAGE_DEP_NGX_BROTLI_COMMIT=
export IMAGE_DEP_NGX_FANCYINDEX_VERSION=
export IMAGE_DEP_NGX_FANCYINDEX_COMMIT=
export IMAGE_FREENGINX_VERSION=
export IMAGE_FREENGINX_COMMIT=
export IMAGE_BUILD_REVISION=

# See .github/workflows/build-image.yaml
export IMAGE_BUILDAH_VERSION=
export IMAGE_BUILDAH_DIGEST=

podman run \
    --rm -it \
    --device /dev/fuse \
    --security-opt label=disable \
    -v "$PWD:/workspace" \
    -w /workspace \
    -e IMAGE_NAME="${IMAGE_NAME}" \
    -e IMAGE_REGISTRY="${IMAGE_REGISTRY}" \
    -e IMAGE_DEP_OPENSSL_VERSION="${IMAGE_DEP_OPENSSL_VERSION}" \
    -e IMAGE_DEP_OPENSSL_COMMIT="${IMAGE_DEP_OPENSSL_COMMIT}" \
    -e IMAGE_DEP_PCRE_VERSION="${IMAGE_DEP_PCRE_VERSION}" \
    -e IMAGE_DEP_PCRE_COMMIT="${IMAGE_DEP_PCRE_COMMIT}" \
    -e IMAGE_DEP_ZLIB_NG_VERSION="${IMAGE_DEP_ZLIB_NG_VERSION}" \
    -e IMAGE_DEP_ZLIB_NG_COMMIT="${IMAGE_DEP_ZLIB_NG_COMMIT}" \
    -e IMAGE_DEP_MIMALLOC_VERSION="${IMAGE_DEP_MIMALLOC_VERSION}" \
    -e IMAGE_DEP_MIMALLOC_COMMIT="${IMAGE_DEP_MIMALLOC_COMMIT}" \
    -e IMAGE_DEP_NGX_BROTLI_COMMIT="${IMAGE_DEP_NGX_BROTLI_COMMIT}" \
    -e IMAGE_DEP_NGX_FANCYINDEX_VERSION="${IMAGE_DEP_NGX_FANCYINDEX_VERSION}" \
    -e IMAGE_DEP_NGX_FANCYINDEX_COMMIT="${IMAGE_DEP_NGX_FANCYINDEX_COMMIT}" \
    -e IMAGE_FREENGINX_VERSION="${IMAGE_FREENGINX_VERSION}" \
    -e IMAGE_FREENGINX_COMMIT="${IMAGE_FREENGINX_COMMIT}" \
    -e IMAGE_BUILD_REVISION="${IMAGE_BUILD_REVISION}" \
    --user=root \
    quay.io/buildah/stable:v${IMAGE_BUILDAH_VERSION}@sha256:${IMAGE_BUILDAH_DIGEST} \
    ./build.sh
```

## License

The build scripts, Dockerfiles, and other assets are under the MIT License; pre-built OCI images do follow the original project's BSD-2-Clause License.
