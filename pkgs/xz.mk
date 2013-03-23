# public domain, LGPL2+, GPL2+, GPL3+, custom (all premissive)
XZ = xz-$(XZ_VERSION)
CLEAN_DIR += "$(XZ)"
packages: xz
xz:
	[ -f "$(XZ).tar.gz" ] || \
	wget "http://tukaani.org/xz/$(XZ).tar.gz"
	[ -d "$(XZ)" ] || \
	tar --gzip --get < "$(XZ).tar.gz"
	cd "$(XZ)" && \
	./configure --prefix=/usr --disable-rpath --enable-werror && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -d -m755 "$(MNT)"/usr/share/licenses/xz/ && \
	sudo ln -sf /usr/share/doc/xz/COPYING "$(MNT)"/usr/share/licenses/xz/COPYING && \
	sudo ln -sf /usr/share/licenses/common/LGPL2.1/license.txt "$(MNT)"/usr/share/doc/xz/COPYING.LGPLv2 && \
	sudo ln -sf /usr/share/licenses/common/GPL2/license.txt "$(MNT)"/usr/share/doc/xz/COPYING.GPLv2 && \
	sudo ln -sf /usr/share/licenses/common/GPL3/license.txt "$(MNT)"/usr/share/doc/xz/COPYING.GPLv3 && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

