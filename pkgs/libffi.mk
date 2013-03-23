# MIT
LIBFFI = libffi-$(LIBFFI_VERSION)
CLEAN_DIR += "$(LIBFFI)"
packages: libffi
libffi:
	[ -f "$(LIBFFI).tar.gz" ] || \
	wget "ftp://sourceware.org/pub/libffi/$(LIBFFI).tar.gz"
	[ -d "$(LIBFFI)" ] || \
	tar --gzip --get < "$(LIBFFI).tar.gz"
	cd "$(LIBFFI)" && \
	./configure --prefix=/usr --disable-static && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/libffi/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

