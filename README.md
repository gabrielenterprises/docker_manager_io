# Docker Manager.io with Automated Supply Chain Security

This repository provides a secure, automated Docker image build pipeline for [Manager.io](https://github.com/Manager-io/Manager) with comprehensive supply chain security measures.

## 🔒 Security Features

### Automated Supply Chain Security (SLSA-aligned)

This project implements automated supply chain security best practices that require **zero manual intervention** and leave a complete, reproducible audit trail:

1. **✅ Release Tag Signature Verification** - Verifies upstream Manager.io release tags are signed
2. **✅ VirusTotal Malware Scanning** - Scans downloaded binaries before build (optional, requires API key)
3. **✅ SHA256 Hash Verification** - Computes and logs cryptographic hashes of all binaries
4. **✅ Digest-Pinned Base Images** - All base images pinned by SHA256 digest for reproducibility
5. **✅ Cosign Image Signing** - Built images signed with Sigstore Cosign (keyless)
6. **✅ Build Manifests** - Complete build metadata committed to Git for audit trail
7. **✅ Audit Logs** - Historical record of all builds with security verification status

### Benefits

- 🔐 **Supply Chain Secure**: SLSA-aligned practices with multiple verification layers
- 🤖 **Fully Automated**: No manual steps, impossible to forget
- 📝 **Auditable**: Complete manifest and logs in Git history
- 🔄 **Reproducible**: Anyone can rebuild with identical results using pinned digests
- ✅ **Verifiable**: VirusTotal scans, signature verification, and Cosign signing

## 🚀 Quick Start

### Prerequisites

1. **Required**: GitHub repository with Actions enabled
2. **Optional**: VirusTotal API key (for malware scanning)
   - Get a free API key at: https://www.virustotal.com/gui/my-apikey
   - Add as repository secret: `VIRUSTOTAL_API_KEY`

### Running a Build

The build workflow can be triggered in two ways:

1. **Manual Trigger**: Go to Actions → Builder → Run workflow
2. **Automatic Trigger**: Runs daily via scheduler when new Manager.io version detected

### Verifying Image Signatures

To verify a signed image with Cosign:

```bash
# Install Cosign
brew install sigstore/tap/cosign  # macOS
# or download from: https://github.com/sigstore/cosign/releases

# Verify the image signature
cosign verify \
  --certificate-identity-regexp="https://github.com/gabrielenterprises/docker_manager_io" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/gabrielenterprises/docker_manager_io:latest
```

## 📋 Build Artifacts

### Build Manifests

Each build creates a JSON manifest (`build-manifest-<version>.json`) containing:

```json
{
  "version": "v5.1.2",
  "build_timestamp": "2026-02-17T12:00:00Z",
  "github_sha": "abc123...",
  "binary": {
    "amd64_sha256": "def456...",
    "download_url": "https://github.com/Manager-io/Manager/releases/download/..."
  },
  "base_images": {
    "alpine": {
      "digest": "sha256:...",
      "reference": "alpine@sha256:..."
    },
    "dotnet_runtime_deps": {
      "digest": "sha256:...",
      "reference": "mcr.microsoft.com/dotnet/runtime-deps@sha256:..."
    }
  },
  "docker_image": {
    "digest": "sha256:...",
    "tags": ["latest", "5.1.2", "5.1.2-abc123"],
    "platforms": ["linux/amd64", "linux/arm64"],
    "signed_with_cosign": true
  }
}
```

### Audit Log

The `audit.log` file maintains a historical record of all builds:

```
========================================
Build Date: 2026-02-17 12:00:00 UTC
Version: v5.1.2
GitHub SHA: abc123...
Run ID: 1234567890
Binary SHA256: def456...
Image Digest: sha256:ghi789...
Cosign Signed: Yes
Manifest: build-manifest-5.1.2.json
========================================
```

## 🔧 Configuration

### Repository Secrets

| Secret Name | Required | Description |
|------------|----------|-------------|
| `VIRUSTOTAL_API_KEY` | Optional | VirusTotal API key for binary malware scanning. If not set, VirusTotal scan is skipped with a warning. |
| `GITHUB_TOKEN` | Auto | Automatically provided by GitHub Actions (no setup needed) |

### Base Image Digests

Base images are pinned by digest in the Dockerfile for reproducibility. To update:

1. Pull latest images:
   ```bash
   docker pull alpine:latest
   docker pull mcr.microsoft.com/dotnet/runtime-deps:8.0
   ```

2. Get digests:
   ```bash
   docker inspect alpine:latest | jq -r '.[0].RepoDigests[0]'
   docker inspect mcr.microsoft.com/dotnet/runtime-deps:8.0 | jq -r '.[0].RepoDigests[0]'
   ```

3. Update the `FROM` statements in `Dockerfile`

## 🏗️ Build Process

The automated build workflow performs these steps:

1. **Get Latest Release** - Fetches latest Manager.io version from GitHub API
2. **Verify Tag Signature** - Attempts GPG verification of release tag
3. **Download Binary** - Downloads amd64 binary for verification
4. **VirusTotal Scan** - Submits binary to VirusTotal (if API key configured)
5. **Compute Hash** - Calculates SHA256 hash of binary
6. **Get Base Digests** - Records base image digests
7. **Build Image** - Multi-arch build (amd64, arm64)
8. **Sign Image** - Cosign keyless signing via Sigstore
9. **Create Manifest** - Generates build manifest JSON
10. **Update Audit Log** - Appends to audit.log
11. **Commit Artifacts** - Pushes manifest and log to Git
12. **Create Release** - Creates GitHub release with image info

## 🐳 Using the Docker Image

### Pull the Image

```bash
# Latest version
docker pull ghcr.io/gabrielenterprises/docker_manager_io:latest

# Specific version
docker pull ghcr.io/gabrielenterprises/docker_manager_io:5.1.2

# Specific build
docker pull ghcr.io/gabrielenterprises/docker_manager_io:5.1.2-abc123def456
```

### Run Manager.io

```bash
docker run -d \
  -p 8080:8080 \
  -v manager-data:/data \
  --name manager \
  ghcr.io/gabrielenterprises/docker_manager_io:latest
```

Access Manager.io at: http://localhost:8080

### Data Persistence

Data is stored in `/data` volume. To backup:

```bash
docker run --rm -v manager-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/manager-backup.tar.gz -C /data .
```

## 📊 Reproducible Builds

To reproduce a specific build:

1. Find the build manifest in the repository (e.g., `build-manifest-5.1.2.json`)
2. Use the exact base image digests and Manager.io version from the manifest
3. Build with:
   ```bash
   docker buildx build \
     --platform linux/amd64,linux/arm64 \
     --build-arg MANAGER_VERSION=v5.1.2 \
     -t manager-io:reproduced \
     .
   ```

The resulting image should match the digest in the manifest.

## 🔍 Security Verification Checklist

For each build, the following verifications are performed:

- [ ] ✅ Upstream release tag signature verified (or noted if unsigned)
- [ ] ✅ Binary downloaded from official GitHub release
- [ ] ✅ SHA256 hash computed and logged
- [ ] ✅ VirusTotal scan passed (if API key configured)
- [ ] ✅ Base images pinned by digest
- [ ] ✅ Multi-arch image built
- [ ] ✅ Image signed with Cosign
- [ ] ✅ Build manifest created and committed
- [ ] ✅ Audit log updated

## 🤝 Contributing

When contributing to this repository:

1. Ensure all security features remain functional
2. Update documentation if adding new features
3. Test workflow changes in a fork before submitting PR
4. Maintain backward compatibility with existing manifests

## 📜 License

This repository is licensed under GPL-3.0 (same as upstream Manager.io).

The Manager.io application itself is copyright [Manager.io](https://github.com/Manager-io/Manager) and licensed under GPL-3.0.

## 🔗 Links

- **Upstream**: https://github.com/Manager-io/Manager
- **Docker Images**: https://github.com/gabrielenterprises/docker_manager_io/pkgs/container/docker_manager_io
- **Documentation**: https://www.manager.io/guides
- **Cosign**: https://github.com/sigstore/cosign
- **VirusTotal**: https://www.virustotal.com
