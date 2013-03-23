# GPL
LIBNL = libnl-$(LIBNL_VERSION)
CLEAN_DIR += "$(LIBNL)"
packages: libnl
libnl:
	[ -f "$(LIBNL).tar.gz" ] || \
	wget "http://www.infradead.org/~tgr/libnl/files/$(LIBNL).tar.gz"
	[ -d "$(LIBNL)" ] || \
	tar --gzip --get < "$(LIBNL).tar.gz"
	cd "$(LIBNL)" && \
	./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --disable-static && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

