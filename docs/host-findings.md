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

On the current boot, the first USB device-descriptor read on `usb2-2` failed
once with `-71` (`EPROTO`); the immediate retry succeeded and enumerated the
adapter as `0a12:0001`. The error occurs before `btusb` binds, so the DKMS
driver cannot correct that first-read failure. No repeated descriptor or
disconnect errors were present in the inspected log.

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

A BlueZ `Naga V2 HS` record exists under local adapter address
`3C:9C:0F:60:68:C2`, while the active controller address is
`00:15:83:15:A3:10`. `bluetoothctl devices` lists no device on the active
controller. The saved record has `Trusted=true` but no `Paired=true` field;
its LE-only technology entry therefore does not establish the current mouse's
Bluetooth transport or pairing state.

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
latest reinstall has not yet been observed.

The `Set Event Filter` warning is the Bluetooth core reporting
`HCI_QUIRK_BROKEN_FILTER_CLEAR_ALL`, which the clone-specific `btusb` setup
enables. In this kernel the quirk makes the event-filter helper return before
it sends `HCI_OP_SET_EVENT_FLT`; removing it could send the command that locks
up some clone controllers. This warning describes the active protection, not
a failed command transaction. Earlier stored-link-key and erroneous-data
warnings in this boot's log came from the module loaded before the latest
reload; the current module masks those advertised command bits.

This host boots with Dracut 110 (`dracut-cmdline.service` ran during the
current boot); the `initramfs-tools` package is not installed. The root-only
`lsinitrd` listing of `/boot/initrd.img-7.0.0-34-generic` contains no `btusb`
module. It does contain the DKMS `8812au` and `nouveau` modules. The active
`/etc/dracut.conf.d/99-portable-usb.conf` sets `hostonly="no"` and does not
request `btusb`. The Bluetooth module therefore loads after root is mounted,
from `/lib/modules/7.0.0-34-generic/updates/dkms/btusb.ko.zst`. No Dracut
configuration change is needed for this module.

## Result

The driver lifecycle fixes are installed from the correctly named 7.0 source
variant. Mouse pairing remains unverified. The next useful check is a pairing
attempt with the mouse in its Bluetooth mode, using BR/EDR discovery.
