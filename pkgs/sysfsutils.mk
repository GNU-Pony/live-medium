# GPL, LGPL
SYSFSUTILS = sysfsutils-$(SYSFSUTILS_VERSION)
CLEAN_DIR += "$(SYSFSUTILS)"
packages: sysfsutils
sysfsutils:
	[ -f "$(SYSFSUTILS).tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/linux-diag/$(SYSFSUTILS).tar.gz"
	[ -d "$(SYSFSUTILS)" ] || \
	tar --gzip --get < "$(SYSFSUTILS).tar.gz"
	cd "$(SYSFSUTILS)" && \
	./configure --prefix=/usr --mandir=/usr/share/man && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm "$(MNT)"/usr/lib/libsysfs.a && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

