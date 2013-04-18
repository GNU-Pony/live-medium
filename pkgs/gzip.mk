# GPL3
GZIP = gzip-$(GZIP_VERSION)
CLEAN_DIR += "$(GZIP)"
packages: gzip
gzip:
	[ -f "$(GZIP).tar.xz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/gzip/$(GZIP).tar.xz"
	[ -d "$(GZIP)" ] || \
	tar --xz --get < "$(GZIP).tar.xz"
	cd "$(GZIP)" && \
	./configure --prefix=/usr && \
	patch -p1 -i ../patches/gzip-1.5-yesno-declaration.patch && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

