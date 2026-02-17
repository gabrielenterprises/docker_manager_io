# Security Policy

## Supply Chain Security

This project implements comprehensive supply chain security measures to ensure the Docker images built from upstream Manager.io releases are trustworthy and secure.

### Upstream Signature Verification

**Important Context**: Manager.io does not publish GPG signatures for their binary releases. However, all release tags on GitHub are automatically signed by GitHub itself using GitHub's GPG key (Key ID: B5690EEEBB952194).

#### What We Verify

Our workflow verifies release authenticity through the following method:

1. **GitHub Release API Verification**: We confirm that the release tag exists in the official Manager.io repository using GitHub's API. This proves:
   - The tag is a genuine GitHub release (GitHub-verified signature)
   - The release was created through GitHub's release system
   - The tag points to a specific commit in the official repository

#### Limitations

- Manager.io does not sign their binaries with GPG, so we cannot verify binary-level signatures
- GitHub's signature on tags proves the tag exists on GitHub, but not that the binary contents are signed by Manager.io maintainers

### Compensating Security Controls

To address the lack of upstream binary signatures, we implement multiple additional security layers:

1. **VirusTotal Malware Scanning** (Optional)
   - Scans downloaded binaries with 70+ antivirus engines
   - Requires `VIRUSTOTAL_API_KEY` repository secret
   - Workflow continues with warning if API key not configured
   - Failed scans block the build

2. **SHA256 Hash Verification**
   - All binaries are hashed immediately after download
   - Hashes are logged in build manifests for audit trail
   - Enables detection of tampering or corruption

3. **Digest-Pinned Base Images**
   - All base images are pinned by SHA256 digest
   - Ensures reproducible builds
   - Prevents supply chain attacks through base image updates

4. **Cosign Image Signing**
   - All built images are signed using Sigstore Cosign (keyless)
   - Signatures can be verified independently
   - Proves images were built by our GitHub Actions workflow

5. **Build Manifests**
   - Complete metadata for every build committed to Git
   - Includes binary hashes, base image digests, and build timestamps
   - Creates immutable audit trail

6. **Audit Logs**
   - Historical record of all builds maintained in repository
   - Enables tracking of what was built and when

### Security Verification Checklist

Each build performs the following verifications:

- ✅ Upstream release tag verified via GitHub API
- ✅ Binary downloaded from official GitHub release
- ✅ SHA256 hash computed and logged
- ✅ VirusTotal scan passed (if API key configured) or warning logged
- ✅ Base images pinned by digest
- ✅ Multi-arch image built
- ✅ Image signed with Cosign
- ✅ Build manifest created and committed
- ✅ Audit log updated

### Example Release Verification Output

When a build completes, the GitHub release notes show the verification results:

```
**Upstream Manager.io**
- Release: v26.2.13.3181
- Verification Method: GitHub Release API

**Security Verification**
- Manager.io Release Signature: ✅ Verified
  - Details: Release tag exists on GitHub (GitHub-verified signature)
- VirusTotal Scan: ✅ Clean (70 engines, 0 malicious)
  - Binary SHA256: abc123...
  - [View Scan Results](https://www.virustotal.com/gui/file/abc123.../detection)
  - Details: 0 malicious detections from 70 security vendors
```

### Verifying Built Images

You can independently verify our built images using Cosign:

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

Successful verification proves:
- The image was built by our GitHub Actions workflow
- The image has not been tampered with since signing
- The build occurred in our verified CI/CD pipeline

## Reporting a Vulnerability

If you discover a security vulnerability in this repository or the build process, please report it by:

1. **DO NOT** open a public issue
2. Email the repository maintainer with details
3. Include steps to reproduce if applicable
4. Allow reasonable time for a fix before public disclosure

### What to Report

- Vulnerabilities in the Docker image or Dockerfile
- Security issues in the build workflow
- Problems with verification or signing processes
- Weaknesses in our supply chain security

### What NOT to Report

- Vulnerabilities in upstream Manager.io software (report those to Manager.io maintainers)
- Issues with base images (report to Alpine or Microsoft)
- General security questions (use GitHub Discussions instead)

## Security Best Practices for Users

When using our Docker images:

1. **Always Verify Signatures**
   ```bash
   cosign verify \
     --certificate-identity-regexp="https://github.com/gabrielenterprises/docker_manager_io" \
     --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
     ghcr.io/gabrielenterprises/docker_manager_io:latest
   ```

2. **Use Specific Version Tags**
   - Prefer `26.2.13.3181` over `latest` for reproducibility
   - Use immutable tags like `26.2.13.3181-abc123def456` for critical deployments

3. **Review Build Manifests**
   - Check the build manifest for your version in the repository
   - Verify the binary SHA256 matches what you expect
   - Review the VirusTotal scan results link

4. **Keep Images Updated**
   - Monitor for new releases
   - Update regularly to get security fixes from upstream Manager.io

5. **Network Security**
   - Run containers in isolated networks
   - Use firewalls to restrict access
   - Enable TLS/HTTPS for production deployments

## Supply Chain Security Resources

- [SLSA Framework](https://slsa.dev/)
- [Sigstore/Cosign Documentation](https://docs.sigstore.dev/)
- [VirusTotal](https://www.virustotal.com/)
- [GitHub Actions Security](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions)

## Security Updates

This SECURITY.md file will be updated when:
- New security features are added to the build process
- Security policies change
- New threats or mitigations are identified
- Upstream Manager.io changes their signing practices

Last Updated: 2026-02-17
