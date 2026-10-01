# Source provenance

The DKMS packaging and per-kernel workaround variants originate from
[`hhsnake/csr8510-fix`](https://github.com/hhsnake/csr8510-fix). Their upstream
credits and GPL-2.0 license are preserved in the repository.

The manifests in this directory pin the Linux source commit, pristine source
file hashes, and patch path for each reproducible variant. `scripts/regen.sh`
fetches and verifies these files before applying the patch. The additional
`kernel-6.17/` and `kernel-7.0.0/` trees retain the exact reference files used
during the CSR dongle investigation documented in `docs/host-findings.md`.
