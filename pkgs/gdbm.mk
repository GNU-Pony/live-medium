# GPL
GDBM = gdbm-$(GDBM_VERSION)
CLEAN_DIR += "$(GDBM)"
packages: gdbm
gdbm:
	[ -f "$(GDBM).tar.gz" ] || \
	wget "ftp://ftp.gnu.org/gnu/gdbm/$(GDBM).tar.gz"
	[ -d "$(GDBM)" ] || \
	tar --gzip --get < "$(GDBM).tar.gz"
	cd "$(GDBM)" && \
	patch -Np1 -i ../patches/gdbm-1.10-zeroheaders.patch && \
	./configure --prefix=/usr --mandir=/usr/share/man \
	        --infodir=/usr/share/info --enable-libgdbm-compat && \
	make prefix=/usr && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix="$(MNT)"/usr manprefix="$(MNT)"/usr/share/man \
	    man3dir="$(MNT)"/usr/share/man/man3 infodir="$(MNT)"/usr/share/info install && \
	sudo install -dm755 "$(MNT)"/usr/include/gdbm && \
	sudo ln -sf ../gdbm.h "$(MNT)"/usr/include/gdbm/gdbm.h && \
	sudo ln -sf ../ndbm.h "$(MNT)"/usr/include/gdbm/ndbm.h && \
	sudo ln -sf ../dbm.h  "$(MNT)"/usr/include/gdbm/dbm.h && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

