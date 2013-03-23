# LGPL
LIBGCRYPT = libgcrypt-$(LIBGCRYPT_VERSION)
CLEAN_DIR += "$(LIBGCRYPT)"
packages: libgcrypt
libgcrypt:
	[ -f "$(LIBGCRYPT).tar.bz2" ] || \
	wget "ftp://ftp.gnupg.org/gcrypt/libgcrypt/$(LIBGCRYPT).tar.bz2"
	[ -d "$(LIBGCRYPT)" ] || \
	tar --bzip2 --get < "$(LIBGCRYPT).tar.bz2"
	cd "$(LIBGCRYPT)" && \
	./configure --prefix=/usr --disable-static --disable-padlock-support && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

