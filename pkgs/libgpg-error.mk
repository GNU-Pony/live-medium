# LGPL
LIBGPG_ERROR = libgpg-error-$(LIBGPG_ERROR_VERSION)
CLEAN_DIR += "$(LIBGPG_ERROR)"
packages: libgpg-error
libgpg-error:
	[ -f "$(LIBGPG_ERROR).tar.gz" ] || \
	wget "ftp://ftp.gnupg.org/gcrypt/libgpg-error/$(LIBGPG_ERROR).tar.gz"
	[ -d "$(LIBGPG_ERROR)" ] || \
	tar --gzip --get < "$(LIBGPG_ERROR).tar.gz"
	cd "$(LIBGPG_ERROR)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

