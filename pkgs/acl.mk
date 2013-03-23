# LGPL
ACL = acl-$(ACL_VERSION)
CLEAN_DIR += "$(ACL)"
packages: acl
acl:
	[ -f "$(ACL).src.tar.gz" ] || \
	wget "http://download.savannah.gnu.org/releases/acl/$(ACL).src.tar.gz"
	[ -d "$(ACL)" ] || \
	tar --gzip --get < "$(ACL).src.tar.gz"
	cd "$(ACL)" && \
	export INSTALL_USER=root INSTALL_GROUP=root && \
	./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/usr/lib && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DIST_ROOT="$(MNT)" install install-lib install-dev && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
