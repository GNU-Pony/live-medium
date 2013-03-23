# custom (permissive free)
EXPAT = expat-$(EXPAT_VERSION)
CLEAN_DIR += "$(EXPAT)"
packages: expat
expat:
	[ -f "$(EXPAT).tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/expat/$(EXPAT).tar.gz"
	[ -d "$(EXPAT)" ] || \
	tar --gzip --get < "$(EXPAT).tar.gz"
	cd "$(EXPAT)" && \
	./configure --prefix=/usr --mandir=/usr/share/man && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/expat/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

