# GPL3
TEXINFO = texinfo-$(TEXINFO_VERSION)
CLEAN_DIR += "$(TEXINFO)"
packages: texinfo
texinfo:
	[ -f "$(TEXINFO).tar.xz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/texinfo/$(TEXINFO).tar.xz"
	[ -d "$(TEXINFO)" ] || \
	tar --xz --get < "$(TEXINFO).tar.xz"
	cd "$(TEXINFO)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

