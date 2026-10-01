# Host findings: CSR adapter and Razer Naga V2 HyperSpeed

Observed on 2026-10-01 on kernel `7.0.0-34-generic`.

## Bluetooth controller

The USB adapter enumerates as `0a12:0001`, with USB `bcdUSB 1.10` and
`bcdDevice 1.34`. Its active controller reports HCI/LMP 2.0, LMP subversion
`0x0c5c`, and manufacturer 10 (CSR). The Linux driver classifies this exact
`bcdDevice`/HCI/LMP combination as an unbranded clone.

The HCI LE Read Buffer Size command (`OGF 0x08`, `OCF 0x0002`, opcode
`0x2002`) and LE Read Local Supported Features (`0x2003`) both return status
`0x01`, `Unknown HCI Command`. The controller therefore does not expose LE
through its active firmware. `lsusb -t` also shows this adapter currently
running at full speed (12 Mbps).

That evidence describes this USB unit and its active firmware; it does not
identify the chip die or prove that every device sold under this VID/PID has
the same silicon. Qualcomm specifies the genuine CSR8510 A10 as Bluetooth 4.0,
with Bluetooth LE and USB 2.0 support ([product specifications](https://www.qualcomm.com/bluetooth/products/csr8510)).
The reported HCI 2.0 version and clone signature do not match those capabilities.

Qualcomm's CSR8510 software page lists ROM patches and tools but requires a
Qualcomm account and license agreement to access them. No firmware image has
been identified or validated for this clone, so an arbitrary firmware flash
would risk leaving this adapter unusable. A host-side `btusb` patch cannot add
LE HCI commands the active controller firmware rejects.

## Mouse

The Razer Naga V2 HyperSpeed supports Bluetooth LE and Razer's 2.4 GHz
HyperSpeed mode. See [Razer's specifications](https://mysupport.razer.com/app/answers/detail/a_id/6392/kw/Razer%20Naga%20Pro)
and [Bluetooth pairing instructions](https://mysupport.razer.com/app/answers/detail/a_id/5387/kw/razer%202.4%20wireless).

The connected Razer device identifies as `1532:00b4`, Razer Naga V2
HyperSpeed. Its USB descriptor reports `bcdUSB 2.00`, although the current
USB link is full speed (12 Mbps). This USB enumeration is separate from the
CSR Bluetooth controller. HCI is the host-controller interface between Linux
and the Bluetooth controller; the mouse does not need to implement host-side
HCI. No Bluetooth pairing attempt was made.

## Driver changes and log status

The `src/6.17` variant installed through DKMS includes these fixes:

- resume the CSR device's runtime-PM state before waking its child USB
  interface, avoiding the inactive-parent/active-child warning;
- ignore expected `-ENOENT` URB completions during shutdown so the interrupt
  completion handler does not resubmit work after unlink.

The source variant is pinned to upstream Linux commit
`e5f0a698b34ed76002dc5cff3804a61c80233a7a`. The pristine `btusb.c` and the
Linux Bluetooth core reference files are retained under `provenance/`.
`scripts/verify.sh 6.17` reproduced the source from its pinned hashes and
patch. DKMS is installed for the running kernel, and its source matches
`src/6.17/btusb.c`.

The latest module reload showed no PM parent/child warning or shutdown URB
resubmit error. Earlier boot/reload messages in this boot journal predate the
final module install. The remaining `HCI ... advertised, but not supported`
messages are emitted by Linux when it records the clone-specific quirks that
skip commands the controller firmware misreports. They identify unsupported
controller commands; they are not failures of the PM or URB fixes.

The current initramfs does not contain `btusb`; `modprobe` resolves it to the
DKMS copy in `updates/dkms`. A fresh boot after the final module install has
not yet been observed.

## Result

The driver lifecycle faults have been patched and the current DKMS module is
active. Bluetooth LE mouse pairing remains unverified and cannot proceed with
the controller's current HCI firmware response. A validated firmware image
for this exact adapter or an LE-capable controller is still needed.
