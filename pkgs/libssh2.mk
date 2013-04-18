# BSD
LIBSSH2 = libssh2-$(LIBSSH2_VERSION)
CLEAN_DIR += "$(LIBSSH2)"
packages: libssh2
libssh2:
	[ -f "$(LIBSSH2).tar.gz" ] || \
	wget "http://www.libssh2.org/download/$(LIBSSH2).tar.gz"
	[ -d "$(LIBSSH2)" ] || \
	tar --gzip --get < "$(LIBSSH2).tar.gz"
	cd "$(LIBSSH2)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/libssh2/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

