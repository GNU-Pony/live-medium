# BSD
SHADOW = shadow-$(SHADOW_VERSION)
CLEAN_DIR += "$(SHADOW)"
packages: shadow
shadow:
	[ -f "$(SHADOW).tar.bz2" ] || \
	wget "http://pkg-shadow.alioth.debian.org/releases/$(SHADOW).tar.bz2"
	[ -d "$(SHADOW)" ] || \
	tar --bzip2 --get < "$(SHADOW).tar.bz2"
	cd "$(SHADOW)" && \
	sed -i '/^user\(mod\|add\)_LDADD/s|$$| -lattr|' src/Makefile.am && \
	export LIBS="-lcrypt" && \
	patch -Np1 < ../patches/xstrdup.patch && \
	patch -Np1 < ../patches/shadow-strncpy-usage.patch && \
	sed -i '/^SUBDIRS/s/pam.d//' etc/Makefile.in && \
	./configure --prefix=/usr --libdir=/lib --mandir=/usr/share/man --sysconfdir=/etc \
	        --with-libpam --without-selinux --with-group-name-max-length=32 && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 ../patches/shadow-license "$(MNT)"/usr/share/licenses/shadow/LICENSE && \
	sudo install -Dm644 ../confs/useradd.defaults "$(MNT)"/etc/default/useradd && \
	sudo install -Dm744 ../confs/shadow.cron.daily "$(MNT)"/etc/cron.daily/shadow && \
	sudo install -Dm644 ../confs/login.defs "$(MNT)"/etc/login.defs && \
	sudo install -dm755 "$(MNT)"/etc/pam.d && \
	sudo install -t "$(MNT)"/etc/pam.d -m644 ../confs/{passwd,chgpasswd,chpasswd,newusers} && \
	sudo install -Dm644 etc/pam.d/groupmems "$(MNT)"/etc/pam.d/groupmems && \
	for file in chage groupadd groupdel groupmod shadow useradd usermod userdel; do \
	        sudo install -Dm644 ../confs/shadow-defaults.pam "$(MNT)"/etc/pam.d/$$file; \
	done && \
	sudo install -Dm644 ../confs/lastlog.tmpfiles "$(MNT)"/usr/lib/tmpfiles.d/lastlog.conf && \
	sudo rm "$(MNT)"/usr/sbin/logoutd && \
	sudo rm "$(MNT)"/usr/bin/{chsh,chfn,sg} && \
	sudo rm "$(MNT)"/bin/{login,su} && \
	sudo rm "$(MNT)"/usr/sbin/{vipw,vigr} && \
	sudo mv "$(MNT)"/usr/bin/{newgrp,sg} && \
	sudo find "$(MNT)"/usr/share/man \( -name chsh.1 -o -name chfn.1 -o -name su.1 -o -name logoutd.8 -o \
	        -name login.1 -o -name vipw.8 -o -name vigr.8 -o -name newgrp.1 \) -delete && \
	sudo rmdir "$(MNT)"/usr/share/man/{{fi,id,zh_TW}/man1,fi,ko/man8} && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

