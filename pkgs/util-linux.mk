# GPL2
UTIL_LINUX = util-linux-$(UTIL_LINUX_VERSION)
CLEAN_DIR += "$(UTIL_LINUX)"
packages: util-linux
util-linux:
	V="$(UTIL_LINUX_VERSION)" && V="$${V%.*}" && \
	([ -f "$(UTIL_LINUX).tar.xz" ] || \
	wget "http://www.kernel.org/pub/linux/utils/util-linux/v$${V}/$(UTIL_LINUX).tar.xz")
	[ -d "$(UTIL_LINUX)" ] || \
	tar --xz --get < "$(UTIL_LINUX).tar.xz"
	cd "$(UTIL_LINUX)" && \
	./configure --prefix=/usr --libdir=/usr/lib --localstatedir=/run \
	        --enable-fs-paths-extra=/usr/bin:/usr/sbin --enable-raw --enable-vipw \
	        --enable-newgrp --enable-chfn-chsh --enable-write --enable-mesg \
	        --enable-socket-activation && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo chmod 4755 "$(MNT)"/usr/bin/{newgrp,ch{sh,fn}} && \
	sudo install -Dm644 ../confs/pam-common "$(MNT)"/etc/pam.d/chfn && \
	sudo install -m644 ../confs/pam-common "$(MNT)"/etc/pam.d/chsh && \
	sudo install -m644 ../confs/pam-login "$(MNT)"/etc/pam.d/login && \
	sudo install -m644 ../confs/pam-su "$(MNT)"/etc/pam.d/su && \
	sudo install -m644 ../confs/pam-su "$(MNT)"/etc/pam.d/su-l && \
	sudo install -Dm644 ../confs/uuidd.tmpfiles "$(MNT)"/usr/lib/tmpfiles.d/uuidd.conf && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

