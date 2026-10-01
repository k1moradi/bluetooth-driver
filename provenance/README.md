# Source provenance

This checkout carries only the Linux 7.0 source variant. Its pristine files
come from Ubuntu's `linux-source-7.0.0` package version `7.0.0-34.34`; the
source archive's top-level kernel Makefile identifies upstream release
7.0.14. `7.0.manifest` records source file hashes and the patch path.

Run `scripts/verify.sh 7.0` to regenerate the variant from the matching source
archive and compare it byte-for-byte with `src/7.0/`. The original DKMS
packaging and CSR workaround credit are retained in the repository history
and GPL-2.0 license.
