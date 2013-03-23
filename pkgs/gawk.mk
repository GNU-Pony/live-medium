# GPL
GAWK = gawk-$(GAWK_VERSION)
CLEAN_DIR += "$(GAWK)"
packages: gawk
gawk:
	[ -f "$(GAWK).tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/gawk/$(GAWK).tar.gz"
	[ -d "$(GAWK)" ] || \
	tar --gzip --get < "$(GAWK).tar.gz"
	cd "$(GAWK)" && \
	./configure --prefix=/usr --libexecdir=/usr/libexec && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	sudo ln -sf ../usr/bin/gawk "$(MNT)"/bin/gawk && \
	sudo ln -sf gawk "$(MNT)"/bin/awk && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

