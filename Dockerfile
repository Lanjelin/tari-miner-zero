ARG TARI_TAG=4.9.0

# === Stage 1: Download, verify and extract ===
FROM debian:bookworm-slim AS builder

ARG TARI_TAG
ARG tari_url="https://github.com/tari-project/tari/releases/download/v$TARI_TAG/"
ARG tari_zip="tari_suite-$TARI_TAG-d9b1c0d-linux-x86_64.zip"

RUN apt update && apt-get install -y \
      unzip wget ca-certificates binutils && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN wget "$tari_url$tari_zip" && \
    wget "$tari_url$tari_zip.sha256" && \
    sha256sum "$tari_zip.sha256" --check || { echo "Hash mismatch!"; exit 1; } && \
    unzip "$tari_zip"

COPY extract-deps.sh /build/extract-deps.sh
RUN chmod +x extract-deps.sh && \
    /build/extract-deps.sh /build/minotari_miner /out

# Adding a few symlinks
WORKDIR /out/bin
RUN ln -s minotari_miner miner

# === Stage 2: Minimal runtime ===
FROM scratch
ARG TARI_TAG

COPY --from=builder /build/libminotari_mining_helper_ffi.so /bin/libminotari_mining_helper_ffi.so

COPY --from=builder /out/bin /bin
COPY --from=builder /out/lib /lib
COPY --from=builder /out/usr /usr
COPY --from=builder /out/lib64 /lib64

LABEL org.opencontainers.image.title="tari-miner-zero" \
      org.opencontainers.image.description="A rootless, distroless, from-scratch Docker image for running the tari miner." \
      org.opencontainers.image.url="https://ghcr.io/lanjelin/tari-miner-zero" \
      org.opencontainers.image.source="https://github.com/Lanjelin/tari-miner-zero" \
      org.opencontainers.image.documentation="https://github.com/Lanjelin/tari-miner-zero" \
      org.opencontainers.image.version="$TARI_TAG" \
      org.opencontainers.image.authors="Lanjelin" \
      org.opencontainers.image.licenses="GPL-3"

USER 1000:1000
ENTRYPOINT ["/bin/miner"]
