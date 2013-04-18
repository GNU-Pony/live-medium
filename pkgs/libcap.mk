# GPL2
LIBCAP = libcap-$(LIBCAP_VERSION)
CLEAN_DIR += "$(LIBCAP)"
packages: libcap
libcap:
	[ -f "$(LIBCAP).tar.gz" ] || \
	wget "ftp://ftp.archlinux.org/other/libcap/$(LIBCAP).tar.gz"
	[ -d "$(LIBCAP)" ] || \
	tar --gzip --get < "$(LIBCAP).tar.gz"
	cd "$(LIBCAP)" && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix=/usr DESTDIR="$(MNT)" RAISE_SETFCAP=no install && \
	sudo chmod 755 "$(MNT)"/usr/lib/libcap.so.$(LIBCAP_VERSION) && \
	sudo rm "$(MNT)"/usr/lib/libcap.a && \
	sudo install -Dm644 pam_cap/capability.conf "$(MNT)"/usr/share/doc/libcap/capability.conf.example && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

