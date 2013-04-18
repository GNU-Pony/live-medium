# GPL2, LGPL2.1, MIT
# split packages: systemd
# make dependencies: cryptsetup docbook-xsl gobject-introspection gperf gtk-doc intltool
#                    libmicrohttpd libxslt linux-api-headers python quota-tools xz
SYSTEMD = systemd-$(SYSTEMD_VERSION)
CLEAN_DIR += "$(SYSTEMD)"
packages: systemd
systemd:
	[ -f "$(SYSTEMD).tar.xz" ] || \
	wget "http://www.freedesktop.org/software/systemd/$(SYSTEMD).tar.xz"
	[ -d "$(SYSTEMD)" ] || \
	tar --xz --get < "$(SYSTEMD).tar.xz"
	cd "$(SYSTEMD)" && \
	patch -Np1 < ../patches/use-split-usr-path.patch && \
	patch -Np1 < ../patches/0001-journal-pass-the-pid-to-sd_pid_get_owner_uid.patch && \
	patch -Np1 < ../patches/0001-strv-fix-STRV_FOREACH_PAIR-macro-definition.patch && \
	patch -Np1 < ../patches/0001-rules-move-builtin-calls-before-the-permissions-sect.patch && \
	./configure --enable-static --libexecdir=/usr/lib --localstatedir=/var \
	        --sysconfdir=/etc --enable-introspection --enable-gtk-doc --disable-audit \
	        --disable-ima --with-sysvinit-path= --with-sysvrcnd-path= && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo sh -c 'printf "d /run/console 0755 root root\n" > "$(MNT)"/usr/lib/tmpfiles.d/console.conf' && \
	sudo mkdir -p "$(MNT)"/bin && \
	sudo mkdir -p "$(MNT)"/sbin && \
	sudo ln -sf ../usr/lib/systemd/systemd "$(MNT)"/bin/systemd && \
	sudo rm -r "$(MNT)"/etc/systemd/system/getty.target.wants/getty@tty1.service && \
	sudo rm -r "$(MNT)"/etc/rpm && \
	sudo ln -sf ../usr/bin/udevadm "$(MNT)"/sbin/udevadm && \
	sudo ln -sf ../lib/systemd/systemd-udevd "$(MNT)"/usr/bin/udevd && \
	sudo install -m644 tmpfiles.d/legacy.conf "$(MNT)"/usr/lib/tmpfiles.d && \
	sudo sed -i 's#GROUP="dialout"#GROUP="uucp"#g' "$(MNT)"/usr/lib/udev/rules.d/*.rules && \
	sudo sed -i 's#GROUP="tape"#GROUP="storage"#g' "$(MNT)"/usr/lib/udev/rules.d/*.rules && \
	sudo sed -i 's#GROUP="cdrom"#GROUP="optical"#g' "$(MNT)"/usr/lib/udev/rules.d/*.rules && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

