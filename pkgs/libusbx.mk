# LGPL
LIBUSBX = libusbx-$(LIBUSBX_VERSION)
CLEAN_DIR += "$(LIBUSBX)"
packages: libusbx
libusbx:
	[ -f "$(LIBUSBX).tar.bz2" ] || \
	wget "http://downloads.sourceforge.net/libusbx/$(LIBUSBX).tar.bz2"
	[ -d "$(LIBUSBX)" ] || \
	tar --bzip2 --get < "$(LIBUSBX).tar.bz2"
	cd "$(LIBUSBX)" && \
	./configure --prefix=/usr --disable-static && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

