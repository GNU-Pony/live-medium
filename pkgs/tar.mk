# GPL3
TAR = tar-$(TAR_VERSION)
CLEAN_DIR += "$(TAR)"
packages: tar
tar:
	[ -f "$(TAR)".tar.xz ] || \
	wget "ftp://ftp.gnu.org/gnu/tar/$(TAR).tar.xz"
	[ -d "$(TAR)" ] || \
	tar --xz --get < "$(TAR).tar.xz"
	cd "$(TAR)" && \
	sed -i -e '/gets is a/d' gnu/stdio.in.h && \
	./configure --prefix=/usr --libexecdir=/usr/lib/tar --bindir=/bin && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

