# custom (free, GPL-incompatible)
IANA_ETC = iana-etc-$(IANA_ETC_VERSION)
CLEAN_DIR += "$(IANA_ETC)"
packages: iana-etc
iana-etc:
	[ -f "$(IANA_ETC).tar.bz2" ] || \
	wget "http://sethwklein.net/$(IANA_ETC).tar.bz2"
	[ -d "$(IANA_ETC)" ] || \
	tar --bzip2 --get < "$(IANA_ETC).tar.bz2"
	cd "$(IANA_ETC)" && \
	patch -p1 -i ../patches/iana-etc-newer.patch && \
	make get && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/iana-etc/LICENSE && \
	sudo install -Dm644 port-numbers.iana "$(MNT)"/usr/share/iana-etc/port-numbers.iana && \
	sudo install -Dm644 protocol-numbers.iana "$(MNT)"/usr/share/iana-etc/protocol-numbers.iana && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

