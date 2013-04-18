# GPL2, LGPL2.1
KEYUTILS = keyutils-$(KEYUTILS_VERSION)
CLEAN_DIR += "$(KEYUTILS)"
packages: keyutils
keyutils:
	[ -f "$(KEYUTILS).tar.bz2" ] || \
	wget "http://people.redhat.com/~dhowells/keyutils/$(KEYUTILS).tar.bz2"
	[ -d "$(KEYUTILS)" ] || \
	tar --bzip2 --get < "$(KEYUTILS).tar.bz2"
	cd "$(KEYUTILS)" && \
	make CFLAGS="-O2 -pipe -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" \
	        LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" LIBDIR="/usr/lib" USRLIBDIR="/usr/lib" install && \
	sudo chmod a+w "$(MNT)"/etc/request-key.conf && \
	sudo echo "# NFS idmap resolver" >> "$(MNT)"/etc/request-key.conf && \
	sudo echo "create id_resolver * * /usr/sbin/nfsidmap %k %d" >> "$(MNT)"/etc/request-key.conf && \
	sudo chmod a-w "$(MNT)"/etc/request-key.conf && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

