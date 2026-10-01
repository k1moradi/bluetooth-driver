# Bluetooth driver for Linux 7.0

This repository contains the patched Linux `btusb` driver for the unbranded
CSR clone adapter examined on this machine. It packages the driver as a DKMS
module named `csr8510-fix`.
The initial DKMS packaging and CSR workaround are adapted from
[`hhsnake/csr8510-fix`](https://github.com/hhsnake/csr8510-fix).

The repository is deliberately scoped to the host's Linux 7.0 kernel series.
It includes no older kernel source variants. `src/7.0/` is based on Ubuntu's
`linux-source-7.0.0` package version `7.0.0-34.34` (whose source tree reports
upstream release 7.0.14), matching the installed `7.0.0-34-generic` kernel.
The DKMS build uses the installed kernel headers.

## Repository layout

```text
src/7.0/       Patched btusb.c and its four local Bluetooth headers
patches/       Patch for the Ubuntu Linux 7.0 source
provenance/    Source package manifest and host findings
scripts/       Source regeneration and reproducibility checks
docs/          Project page and host-specific findings
```

The selector accepts only kernel releases in the `7.0.x` series, so DKMS will
not silently build these sources against another kernel series.

## Install

On Ubuntu with the 7.0 kernel running:

```bash
sudo apt install git dkms linux-headers-$(uname -r)
git clone https://github.com/k1moradi/bluetooth-driver.git
cd bluetooth-driver
sudo ./install.sh
```

The install script builds and installs only for the running kernel. The module
is placed under `/lib/modules/<kernel>/updates/dkms/`; the in-tree driver is
not overwritten. Check the installation with:

```bash
dkms status csr8510-fix
modinfo -F filename btusb
journalctl -k -b | grep -iE 'bluetooth|csr'
```

To return to the stock driver:

```bash
sudo ./uninstall.sh
```

Secure Boot may require a DKMS signing key enrolled through MOK.

## What the patch changes

The patch handles malformed HCI responses and USB lifecycle problems reported
by this class of fake CSR8510 A10 adapters. It clears Supported Commands bits
for commands the clone advertises but does not implement, pads several short
Command Complete responses, fixes the runtime-PM suspend path, and recovers
from selected controller initialization failures with a USB reset. The
existing device checks keep these changes scoped to detected fake adapters.

## Bluetooth LE limitation on this host

The adapter tested here reports HCI 2.0 and returns `Unknown HCI Command` for
LE controller commands. A host-side driver patch cannot add LE commands that
the active adapter firmware does not implement. The `0a12:0001` USB ID alone
does not identify the silicon or prove that another unit has the same
firmware. See [`docs/host-findings.md`](docs/host-findings.md) for the measured
details.

The Razer Naga V2 HyperSpeed supports Bluetooth LE. Its specifications and
pairing instructions are documented by
[Razer](https://mysupport.razer.com/app/answers/detail/a_id/6392/kw/Razer%20Naga%20Pro)
and [Razer's pairing guide](https://mysupport.razer.com/app/answers/detail/a_id/5387/kw/razer%202.4%20wireless).
Pairing has not been attempted because the adapter's active firmware does not
expose LE.

## Source provenance and verification

Install Ubuntu's matching source package and regenerate the vendored files:

```bash
sudo apt install linux-source-7.0.0
scripts/verify.sh 7.0
```

The manifest pins hashes for each pristine source file before applying
[`patches/csr8510-fix-7.0.patch`](patches/csr8510-fix-7.0.patch). To regenerate
into `src/7.0/` explicitly, run `scripts/regen.sh 7.0`.

To apply the patch to a full Ubuntu 7.0 kernel source tree:

```bash
cd linux-source-7.0.0
patch -p1 < /path/to/bluetooth-driver/patches/csr8510-fix-7.0.patch
```

## Troubleshooting

- If the DKMS build fails, inspect
  `/var/lib/dkms/csr8510-fix/1.0.0/build/make.log`.
- If the desktop cannot discover devices, inspect the controller's LE
  commands with `btmon` and check `journalctl -k`; this patch cannot add LE
  capability missing from adapter firmware.
- If a kernel outside 7.0.x is booted, this package intentionally refuses to
  select a source variant. It contains only `src/7.0/`.
