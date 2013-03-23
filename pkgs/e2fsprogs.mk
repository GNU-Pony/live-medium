# GPL, LGPL, MIT
E2FSPROGS = e2fsprogs-$(E2FSPROGS_VERSION)
CLEAN_DIR += "$(E2FSPROGS)"
packages: e2fsprogs
e2fsprogs:
	[ -f "$(E2FSPROGS).tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/e2fsprogs/$(E2FSPROGS).tar.gz"
	[ -d "$(E2FSPROGS)" ] || \
	tar --gzip --get < "$(E2FSPROGS).tar.gz"
	cd "$(E2FSPROGS)" && \
	sed -i '/init\.d/s|^|#|' misc/Makefile.in && \
	./configure --prefix=/usr --with-root-prefix="" --libdir=/usr/lib \
	        --enable-elf-shlibs --disable-fsck --disable-uuidd \
	        --disable-libuuid --disable-libblkid && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install install-libs && \
	sudo sed -i -e 's/^AWK=.*/AWK=awk/' "$(MNT)/usr/bin/compile_et" && \
	sudo sed -i -e 's#^SS_DIR=.*#SS_DIR="/usr/share/ss"#' "$(MNT)/usr/bin/mk_cmds" && \
	sudo sed -i -e 's#^ET_DIR=.*#ET_DIR="/usr/share/et"#' "$(MNT)/usr/bin/compile_et" && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

