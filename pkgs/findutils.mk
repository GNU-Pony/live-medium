# GPL3
FINDUTILS = findutils-$(FINDUTILS_VERSION)
CLEAN_DIR += "$(FINDUTILS)"
packages: findutils
findutils:
	[ -f "$(FINDUTILS).tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/findutils/$(FINDUTILS).tar.gz"
	[ -d "$(FINDUTILS)" ] || \
	tar --gzip --get < "$(FINDUTILS).tar.gz"
	cd "$(FINDUTILS)" && \
	sed -i '/^SUBDIRS/s/locate//' Makefile.in && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

