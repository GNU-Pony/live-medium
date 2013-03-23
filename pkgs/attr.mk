# LGPL
ATTR = attr-$(ATTR_VERSION)
CLEAN_DIR += "$(ATTR)"
packages: attr
attr:
	[ -f "$(ATTR).src.tar.gz" ] || \
	wget "http://download.savannah.gnu.org/releases/attr/$(ATTR).src.tar.gz"
	[ -d "$(ATTR)" ] || \
	tar --gzip --get < "$(ATTR).src.tar.gz"
	cd "$(ATTR)" && \
	export INSTALL_USER=root INSTALL_GROUP=root && \
	./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/usr/libexec && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DIST_ROOT="$(MNT)" install install-lib install-dev && \
	sudo rm -f "$(MNT)"/usr/lib/libattr.a && \
	sudo chmod 0755 "$(MNT)"/usr/lib/libattr.so.*.*.* && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

