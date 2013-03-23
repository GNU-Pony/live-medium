# BSD
LIBGSSGLUE = libgssglue-$(LIBGSSGLUE_VERSION)
CLEAN_DIR += "$(LIBGSSGLUE)"
packages: libgssglue
libgssglue:
	[ -f "$(LIBGSSGLUE).tar.gz" ] || \
	wget "http://www.citi.umich.edu/projects/nfsv4/linux/libgssglue/$(LIBGSSGLUE).tar.gz"
	[ -d "$(LIBGSSGLUE)" ] || \
	tar --gzip --get < "$(LIBGSSGLUE).tar.gz"
	cd "$(LIBGSSGLUE)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)/" install && \
	sudo install -Dm644 ../confs/gssapi_mech.conf "$(MNT)"/etc/gssapi_mech.conf && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/libgssglue/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

