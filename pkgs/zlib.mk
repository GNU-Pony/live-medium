# custom (all premissive free)
ZLIB = zlib-$(ZLIB_VERSION)
CLEAN_DIR += "$(ZLIB)"
packages: zlib
zlib:
	[ -f "$(ZLIB).tar.gz" ] || \
	wget "http://zlib.net/current/$(ZLIB).tar.gz"
	[ -d "$(ZLIB)" ] || \
	tar --gzip --get < "$(ZLIB).tar.gz"
	cd "$(ZLIB)" && \
	./configure --prefix=/usr && \
	make && \
	grep -A 24 '^  Copyright' zlib.h > LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/zlib/LICENSE
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

