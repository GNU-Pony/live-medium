# custom (permissive free)
FILE = file-$(FILE_VERSION)
CLEAN_DIR += "$(FILE)"
packages: file
file:
	[ -f "$(FILE).tar.gz" ] || \
	wget "ftp://ftp.astron.com/pub/file/$(FILE).tar.gz"
	[ -d "$(FILE)" ] || \
	tar --gzip --get < "$(FILE).tar.gz"
	cd "$(FILE)" && \
	./configure --prefix=/usr --datadir=/usr/share/file && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/file/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

