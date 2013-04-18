# BSD
OPENNTPD = openntpd-$(OPENNTPD_VERSION)
CLEAN_DIR += "$(OPENNTPD)"
packages: openntpd
openntpd:
	[ -f "$(OPENNTPD).tar.gz" ] || \
	wget "ftp://ftp.openbsd.org/pub/OpenBSD/OpenNTPD/$(OPENNTPD).tar.gz"
	[ -d "$(OPENNTPD)" ] || \
	tar --gzip --get < "$(OPENNTPD).tar.gz"
	cd "$(OPENNTPD)" && \
	patch -Np1 -i ../patches/linux-adjtimex.patch && \
	autoreconf -fi && \
	./configure --prefix=/usr --sysconfdir=/etc --with-privsep-user=ntp \
	        --with-privsep-path=/run/openntpd/ --with-adjtimex && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm755 ../confs/openntpd "$(MNT)"/etc/rc.d/openntpd && \
	sudo install -Dm644 ../confs/openntpd.conf "$(MNT)"/etc/conf.d/openntpd && \
	sudo install -Dm644 LICENCE "$(MNT)"/usr/share/licenses/openntpd/LICENCE && \
	sudo sed -i 's/\*/0.0.0.0/' "$(MNT)"/etc/ntpd.conf && \
	sudo install -Dm644 ../patches/openntpd.tmpfiles "$(MNT)"/usr/lib/tmpfiles.d/openntpd.conf && \
	sudo install -dm755 "$(MNT)"/usr/lib/systemd/ntp-units.d && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

