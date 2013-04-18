# BSD
LIBTIRPC = libtirpc-$(LIBTIRPC_VERSION)
CLEAN_DIR += "$(LIBTIRPC)"
packages: libtirpc
libtirpc:
	[ -f "$(LIBTIRPC).tar.bz2" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/libtirpc/$(LIBTIRPC).tar.bz2"
	[ -d "$(LIBTIRPC)" ] || \
	tar --bzip2 --get < "$(LIBTIRPC).tar.bz2"
	cd "$(LIBTIRPC)" && \
	patch -Np1 -i ../patches/libtirpc-0.2.1-fortify.patch && \
	patch -Np1 -i ../patches/libtirpc-0.2.3rc1.patch && \
	patch -Np1 -i ../patches/libtirpc-fix-segfault-0.2.2.patch && \
	./configure --prefix=/usr --enable-gss && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 doc/etc_netconfig "$(MNT)"/etc/netconfig && \
	sudo install -D -m644 COPYING "$(MNT)"/usr/share/licenses/libtirpc/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

