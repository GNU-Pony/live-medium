# GPL3
SED = sed-$(SED_VERSION)
CLEAN_DIR += "$(SED)"
packages: sed
sed:
	[ -f "$(SED).tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/sed/$(SED).tar.gz"
	[ -d "$(SED)" ] || \
	tar --gzip --get < "$(SED).tar.gz"
	cd "$(SED)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	sudo ln -s ../usr/bin/sed "$(MNT)"/bin && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

