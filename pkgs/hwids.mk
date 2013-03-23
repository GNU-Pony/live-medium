# GPL2
HWIDS = hwids-$(HWIDS_VERSION)
CLEAN_DIR += "$(HWIDS)"
packages: hwids
hwids:
	[ -f "$(HWIDS).tar.gz" ] || \
	wget "https://github.com/gentoo/hwids/tarball/hwids-20130228" -O "$(HWIDS).tar.gz"
	[ -d "$(HWIDS)" ] || \
	(tar --gzip --get < "$(HWIDS).tar.gz" && mv gentoo-hwids* "$(HWIDS)")
	cd "$(HWIDS)" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	for ids in pci.ids usb.ids; do \
	    sudo install -Dm644 "$$ids" "$(MNT)/usr/share/hwdata/$${ids}"; \
	done && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

