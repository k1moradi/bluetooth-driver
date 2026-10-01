# Host findings: CSR dongle and Razer Naga V2 HyperSpeed

Observed on 2026-10-01 while working on this machine's Bluetooth setup.

## Controller capability

The connected CSR USB adapter enumerates as `0a12:0001`. Its active controller
reports HCI/LMP version 2.0 and subversion `0x0c5c`. The HCI LE Read Buffer
Size command (`OGF 0x08`, `OCF 0x0002`, opcode `0x2002`) returns status
`0x01` (`Unknown HCI Command`). BlueZ can power and expose `hci0`, but that
does not mean its firmware implements Bluetooth LE.

This is a controller-firmware capability limit. A host-side `btusb` patch can
repair USB transport, power-management, and HCI initialization problems; it
cannot implement missing LE controller commands. Do not spend the mouse's
short pairing window trying to pair it through this adapter.

## Mouse and receiver

The Razer Naga V2 HyperSpeed supports Bluetooth LE as well as Razer's 2.4 GHz
HyperSpeed mode. See [Razer's specifications](https://mysupport.razer.com/app/answers/detail/a_id/6392/kw/Razer%20Naga%20Pro)
and [Bluetooth pairing instructions](https://mysupport.razer.com/app/answers/detail/a_id/5387/kw/razer%202.4%20wireless).

A Razer USB device with product ID `1532:00b4` was also present and identified
as a Naga V2 HyperSpeed. It appears to be the USB receiver path, separate from
the CSR Bluetooth controller. No Bluetooth pairing attempt was made.

## Driver changes and validation

The 6.17 source variant used on kernel `7.0.0-34-generic` was updated to:

- resume the CSR device's runtime-PM state before waking its child USB
  interface, avoiding the inactive-parent/active-child warning;
- ignore expected `-ENOENT` URB completions during shutdown so the interrupt
  completion handler does not try to resubmit work after unlink.

The variant is pinned to upstream Linux commit
`e5f0a698b34ed76002dc5cff3804a61c80233a7a`. The pristine `btusb.c` is retained
under `provenance/kernel-6.17/`; its hash is recorded in
`provenance/6.17.manifest`. The three Linux Bluetooth core files consulted to
classify remaining HCI quirk messages are under
`provenance/kernel-7.0.0/net/bluetooth/`.

`scripts/verify.sh 6.17` reproduces the variant from the pinned source hashes
and patch. The DKMS build was installed for the running kernel. After loading
the updated module, the inactive-parent warning and shutdown URB resubmit
error were absent. The controller's unsupported-command warnings remain
because they describe commands the firmware does not support.

## Practical next step

For Bluetooth LE pairing, use a Bluetooth adapter whose active controller
firmware supports LE HCI commands. The existing Razer receiver may provide
2.4 GHz mouse operation if it is the HyperSpeed receiver and the mouse is set
to that wireless mode.
