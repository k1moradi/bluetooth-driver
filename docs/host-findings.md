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
The reported HCI 2.0 version and clone signature do not match those
capabilities.

Qualcomm's CSR8510 software page lists ROM patches and tools but requires a
Qualcomm account and license agreement to access them. No firmware image has
been identified or validated for this clone, so an arbitrary firmware flash
would risk leaving this adapter unusable. A host-side `btusb` patch cannot add
LE HCI commands the active controller firmware rejects.

## Mouse

Razer lists Bluetooth and 2.4 GHz HyperSpeed connectivity for the Naga V2
HyperSpeed. Its public [specifications](https://mysupport.razer.com/app/answers/detail/a_id/6392/kw/Razer%20Naga%20Pro)
and [Bluetooth pairing instructions](https://mysupport.razer.com/app/answers/detail/a_id/5387/kw/razer%202.4%20wireless)
do not say whether the Bluetooth mode uses BR/EDR or LE. This controller
supports BR/EDR but its active firmware rejects LE HCI commands, so pairing
over BR/EDR remains possible if the mouse supports that transport.

The connected Razer device identifies as `1532:00b4`, Razer Naga V2
HyperSpeed. Its USB descriptor reports `bcdUSB 2.00`, although the current
USB link is full speed (12 Mbps). This USB enumeration is separate from the
CSR Bluetooth controller. HCI is the host-controller interface between Linux
and the Bluetooth controller; the mouse does not need to implement host-side
HCI. No Bluetooth pairing attempt was made.

## Driver changes and log status

The repository now carries only `src/7.0/`, based on Ubuntu's
`linux-source-7.0.0` package version `7.0.0-34.34`. The source tree's top-level
Makefile reports upstream Linux release 7.0.14. `provenance/7.0.manifest`
pins hashes for the pristine `btusb.c` and its local headers, then applies
`patches/csr8510-fix-7.0.patch`. `scripts/verify.sh 7.0` reproduced this
variant from the matching source files.

The selector maps `7.0.0-34-generic` to `src/7.0` and rejects other kernel
series. DKMS was rebuilt from the new variant for the running kernel. The
patched source in `src/7.0/btusb.c` and the copy installed under
`/usr/src/csr8510-fix-1.0.0/src/7.0/btusb.c` have matching SHA-256 hashes.
`modinfo` resolves `btusb` to
`/lib/modules/7.0.0-34-generic/updates/dkms/btusb.ko.zst`.

The latest module reload showed no inactive-parent/active-child PM warning or
shutdown URB resubmit error. It logged the expected unbranded-clone detection,
the new `CSR: masking unsupported advertised HCI commands` message, and the
remaining unsupported `Set Event Filter` warning. A fresh boot after this
latest reinstall has not yet been observed. The current initramfs does not
contain `btusb`; `modprobe` resolves it to the DKMS module.

## Result

The driver lifecycle fixes are installed from the correctly named 7.0 source
variant. Mouse pairing remains unverified. The next useful check is a pairing
attempt with the mouse in its Bluetooth mode, using BR/EDR discovery.
