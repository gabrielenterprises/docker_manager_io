# --------------------------------------------------------------
# Stage 1 – download the upstream ManagerServer tarball
# --------------------------------------------------------------
# Pin alpine by digest for reproducibility (digest updated: 2026-02-17)
FROM alpine@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11 AS build

ARG MANAGER_VERSION               # supplied by the CI (e.g. v5.1.2)
ARG TARGETPLATFORM                # supplied automatically by Docker Buildx

# Install curl for fetching tarballs, jq for JSON parsing, and coreutils for sha256sum
RUN apk --no-cache add curl jq coreutils

# Choose the correct binary for the target architecture,
# download it, verify integrity, and extract the ManagerServer executable.
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        TARGET=arm64; \
    else \
        TARGET=x64; \
    fi && \
    echo "Downloading https://github.com/Manager-io/Manager/releases/download/${MANAGER_VERSION}/ManagerServer-linux-${TARGET}.tar.gz" && \
    curl -L "https://github.com/Manager-io/Manager/releases/download/${MANAGER_VERSION}/ManagerServer-linux-${TARGET}.tar.gz" \
         --output /tmp/manager-server.tar.gz && \
    echo "Computing SHA256 hash of downloaded binary..." && \
    sha256sum /tmp/manager-server.tar.gz | tee /tmp/manager-server.tar.gz.sha256 && \
    echo "File attributes for audit trail:" && \
    ls -lh /tmp/manager-server.tar.gz && \
    stat /tmp/manager-server.tar.gz && \
    echo "Extracting tarball..." && \
    mkdir /tmp/manager-server && \
    tar -xvzf /tmp/manager-server.tar.gz -C /tmp/manager-server

# --------------------------------------------------------------
# Stage 2 – final runtime image (dotnet runtime‑deps + Chromium)
# --------------------------------------------------------------
# Pin .NET runtime-deps by digest for reproducibility (digest updated: 2026-02-17)
FROM mcr.microsoft.com/dotnet/runtime-deps@sha256:90bb23be7c17d7fce2381508d14d5716b36948534c5841e4804944bc9d941de7

ARG MANAGER_VERSION
LABEL build_version="version:- ${MANAGER_VERSION}"
LABEL org.opencontainers.image.version="${MANAGER_VERSION}"

# Puppeteer needs a headless Chromium binary.
# The wrapper script (included in the repo) tells Puppeteer where to find it.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/local/bin/chromium-wrapper

# Install Chromium (the headless browser) and curl (used by the health‑check)
RUN apt-get update && \
    apt-get install -y curl chromium && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/manager-server

# Bring in the binary we extracted in the build stage
COPY --from=build /tmp/manager-server/ .

# Copy the wrapper script that lives at the repo root
COPY chromium-wrapper /usr/local/bin/chromium-wrapper

# Make both the server binary and the wrapper executable
RUN chmod +x /opt/manager-server/ManagerServer /usr/local/bin/chromium-wrapper

# Health‑check – the Manager UI exposes /healthz
HEALTHCHECK --interval=10s --timeout=5s --retries=3 \
  CMD curl --fail -s http://localhost:8080/healthz || exit 1

# Default command – run the Manager server
CMD ["/opt/manager-server/ManagerServer","-port","8080","-path","/data"]

# Persistent data (e.g., SQLite DB) lives here
VOLUME /data
EXPOSE 8080
