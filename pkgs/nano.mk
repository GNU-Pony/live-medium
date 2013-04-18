# GPL
NANO = nano-$(NANO_VERSION)
CLEAN_DIR += "$(NANO)"
packages: nano
nano:
	[ -f "$(NANO).tar.gz" ] || \
	wget "http://www.nano-editor.org/dist/v2.2/$(NANO).tar.gz"
	[ -d "$(NANO)" ] || \
	tar --gzip --get < "$(NANO).tar.gz"
	cd "$(NANO)" && \
	./configure --prefix=/usr --sysconfdir=/etc --enable-color \
	        --enable-nanorc --enable-multibuffer --disable-wrapping-as-root && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -DTm644 doc/nanorc.sample "$(MNT)"/etc/nanorc && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

