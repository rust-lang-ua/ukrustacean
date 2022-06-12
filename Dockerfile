#
# Stage 'dist' creates project distribution.
#

# https://github.com/instrumentisto/rust-docker-image/pkgs/container/rust
ARG rust_ver=latest
FROM ghcr.io/instrumentisto/rust:${rust_ver} AS dist
ARG rustc_mode=release
ARG rustc_opts=--release

# Create the user and group files that will be used in the running container to
# run the process as an unprivileged user.
RUN mkdir -p /out/etc/ \
 && echo 'nobody:x:65534:65534:nobody:/:' > /out/etc/passwd \
 && echo 'nobody:x:65534:' > /out/etc/group

# Update and prepare CA cerificates for TLS connections.
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            ca-certificates \
 && update-ca-certificates \
 && cp -f --parents /etc/ssl/certs/ca-certificates.crt /out/

# Prepare Cargo workspace for building dependencies only.
COPY Cargo.toml Cargo.lock README.md /app/
WORKDIR /app/
RUN mkdir -p src/ && touch src/lib.rs

# Build dependencies only.
RUN cargo build --lib ${rustc_opts}
# Remove fingreprints of pre-built empty project sub-crates
# to rebuild them correctly later.
RUN rm -rf /app/target/${rustc_mode}/.fingerprint/ukrustacean-*

# Prepare project sources for building.
COPY src/ /app/src/

# Build project distribution binary.
# TODO: use --out-dir once stabilized
# TODO: https://github.com/rust-lang/cargo/issues/6790
RUN cargo build --bin=ukrustacean ${rustc_opts}

# Prepare project distribution binary and all dependent dynamic libraries.
RUN cp /app/target/${rustc_mode}/ukrustacean /out/ukrustacean \
 && ldd /out/ukrustacean \
        # These libs are not reported by ldd(1) on binary,
        # but are vital for DNS resolution.
        # See: https://forums.aws.amazon.com/thread.jspa?threadID=291609
        /lib/$(uname -m)-linux-gnu/libnss_dns.so.2 \
        /lib/$(uname -m)-linux-gnu/libnss_files.so.2 \
    | awk 'BEGIN{ORS=" "}$1~/^\//{print $1}$3~/^\//{print $3}' \
    | sed 's/,$/\n/' \
    | tr -d ':' \
    | tr ' ' "\n" \
    | xargs -I '{}' cp -fL --parents '{}' /out/ \
 && rm -rf /out/out

# Prepare l10n files.
COPY l10n/ /out/l10n/




#
# Stage 'runtime' creates final Docker image to use in runtime.
#

# https://hub.docker.com/_/scratch
FROM scratch AS runtime

COPY --from=dist /out/ /

USER nobody:nobody

ENTRYPOINT ["/ukrustacean"]
