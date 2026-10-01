# kbuild part: used by DKMS after select-variant.sh has copied the right
# btusb.c + headers into this directory.
ifneq ($(KERNELRELEASE),)

obj-m := btusb.o

# Ubuntu may backport HCI API changes, so probe the running kernel's headers
# rather than inferring symbol presence from the 7.0 source version.
# HCI_PRIMARY (with dev_type/HCI_AMP) was removed in 6.10; HCI_QUIRK_VALID_LE_STATES
# was inverted to HCI_QUIRK_BROKEN_LE_STATES in 6.11;
# The selected source is the Ubuntu 7.0 variant in src/7.0/.
_hci_h := $(srctree)/include/net/bluetooth/hci.h
ccflags-$(shell grep -qw HCI_PRIMARY $(_hci_h) 2>/dev/null && echo y) += -DHAVE_HCI_PRIMARY
ccflags-$(shell grep -qw HCI_QUIRK_VALID_LE_STATES $(_hci_h) 2>/dev/null && echo y) += -DHAVE_HCI_QUIRK_VALID_LE_STATES
ccflags-$(shell grep -qw HCI_QUIRK_BROKEN_ERR_DATA_REPORTING $(_hci_h) 2>/dev/null && echo y) += -DHAVE_HCI_QUIRK_BROKEN_ERR_DATA_REPORTING
# HCI_QUIRK_BROKEN_READ_PAGE_SCAN_TYPE skips Read Page Scan Type, which the CSR
# clones answer with a truncated payload.
ccflags-$(shell grep -qw HCI_QUIRK_BROKEN_READ_PAGE_SCAN_TYPE $(_hci_h) 2>/dev/null && echo y) += -DHAVE_HCI_QUIRK_BROKEN_READ_PAGE_SCAN_TYPE

# Convenience part: "make" in the repo root builds the module for the
# running kernel without DKMS (for a quick one-off test).
else

KDIR ?= /lib/modules/$(shell uname -r)/build

all:
	./select-variant.sh
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean
	rm -f btusb.c btbcm.h btintel.h btrtl.h btmtk.h

endif
