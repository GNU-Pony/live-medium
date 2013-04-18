# GPL
CRACKLIB = cracklib-$(CRACKLIB_VERSION)
CLEAN_DIR += "$(CRACKLIB)"
packages: cracklib
cracklib:
	[ -f "$(CRACKLIB).tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/cracklib/$(CRACKLIB).tar.gz"
	[ -d "$(CRACKLIB)" ] || \
	tar --gzip --get < "$(CRACKLIB).tar.gz"
	cd "$(CRACKLIB)" && \
	./configure --prefix=/usr --without-python && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 dicts/cracklib-small "$(MNT)"/usr/share/dict/cracklib-small && \
	sudo sh ./util/cracklib-format dicts/cracklib-small | \
	    sudo sh ./util/cracklib-packer "$(MNT)"/usr/share/cracklib/pw_dict && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

