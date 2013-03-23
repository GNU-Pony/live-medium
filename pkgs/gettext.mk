# GPL
GETTEXT = gettext-$(GETTEXT_VERSION)
CLEAN_DIR += "$(GETTEXT)"
packages: gettext
gettext:
	[ -f "$(GETTEXT).tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/gettext/$(GETTEXT).tar.gz"
	[ -d "$(GETTEXT)" ] || \
	tar --gzip --get < "$(GETTEXT).tar.gz"
	cd "$(GETTEXT)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

