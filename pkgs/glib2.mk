# LGPL
GLIB2 = glib-$(GLIB2_VERSION)
GLIB2_MINOR = $(shell echo $(GLIB2_VERSION) | cut -d . -f 1,2)
CLEAN_DIR += "$(GLIB2)"
packages: glib2
glib2:
	[ -f "$(GLIB2).tar.xz" ] || \
	wget "http://ftp.gnome.org/pub/GNOME/sources/glib/$(GLIB2_MINOR)/$(GLIB2).tar.xz"
	[ -d "$(GLIB2)" ] || \
	tar --xz --get < "$(GLIB2).tar.xz"
	cd "$(GLIB2)" && \
	patch -Rp1 -i ../patches/revert-warn-glib-compile-schemas.patch && \
	export PYTHON=/usr/bin/python2 && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc --with-pcre=system --disable-fam && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make completiondir=/usr/share/bash-completion/completions DESTDIR="$(MNT)" install && \
	for s in "$(MNT)"/usr/share/bash-completion/completions/*; do  sudo chmod -x "$$s"; done && \
	sudo sed -i "s_#!/usr/bin/env python_#!/usr/bin/env python2_" "$(MNT)"/usr/bin/gdbus-codegen && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

