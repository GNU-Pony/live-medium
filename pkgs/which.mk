# GPL3
WHICH = which-$(WHICH_VERSION)
CLEAN_DIR += "$(WHICH)"
packages: which
which:
	[ -f "$(WHICH).tar.gz" ] || \
	wget "http://www.xs4all.nl/~carlo17/which/$(WHICH).tar.gz"
	[ -d "$(WHICH)" ] || \
	tar --gzip --get < "$(WHICH).tar.gz"
	cd "$(WHICH)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

