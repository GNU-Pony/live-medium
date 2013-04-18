# LGPL3
GMP = gmp-$(GMP_VERSION)
CLEAN_DIR += "$(GMP)"
packages: gmp
gmp:
	[ -f "$(GMP).tar.xz" ] || \
	wget "ftp://ftp.gmplib.org/pub/$(GMP)/$(GMP).tar.xz"
	[ -d "$(GMP)" ] || \
	tar --xz --get < "$(GMP).tar.xz"
	cd "$(GMP)" && \
	./configure --build=$(CHOST) --prefix=/usr --enable-cxx && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

