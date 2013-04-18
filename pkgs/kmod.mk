# GPL2
KMOD = kmod-$(KMOD_VERSION)
CLEAN_DIR += "$(KMOD)"
packages: kmod
kmod:
	[ -f "$(KMOD).tar.xz" ] || \
	wget "ftp://ftp.kernel.org/pub/linux/utils/kernel/kmod/$(KMOD).tar.xz"
	[ -d "$(KMOD)" ] || \
	tar --xz --get < "$(KMOD).tar.xz"
	cd "$(KMOD)" && \
	./configure --sysconfdir=/etc --enable-gtk-doc --with-zlib && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)/" install && \
	sudo install -dm755 "$(MNT)"/{etc,usr/lib}/{depmod,modprobe}.d "$(MNT)/sbin" && \
	sudo ln -sf ../usr/bin/kmod "$(MNT)/sbin/modprobe" && \
	sudo ln -sf ../usr/bin/kmod "$(MNT)/sbin/depmod" && \
	for tool in {ins,ls,rm}mod modinfo; do \
	    sudo ln -sf kmod "$(MNT)/usr/bin/$$tool"; \
	done && \
	sudo install -Dm644 "../confs/depmod-search.conf" "$(MNT)/usr/lib/depmod.d/search.conf" && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

