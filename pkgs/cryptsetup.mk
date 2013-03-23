# GPL
CRYPTSETUP = cryptsetup-$(CRYPTSETUP_VERSION)
CLEAN_DIR += "$(CRYPTSETUP)"
packages: cryptsetup
cryptsetup:
	[ -f "$(CRYPTSETUP).tar.bz2" ] || \
	wget "http://cryptsetup.googlecode.com/files/$(CRYPTSETUP).tar.bz2"
	[ -d "$(CRYPTSETUP)" ] || \
	tar --bzip2 --get < "$(CRYPTSETUP).tar.bz2"
	cd "$(CRYPTSETUP)" && \
	./configure --prefix=/usr --disable-static --enable-cryptsetup-reencrypt && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

