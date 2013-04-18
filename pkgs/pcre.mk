# BSD
PCRE = pcre-$(PCRE_VERSION)
CLEAN_DIR += "$(PCRE)"
packages: pcre
pcre:
	[ -f "$(PCRE).tar.bz2" ] || \
	wget "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/$(PCRE).tar.bz2"
	[ -d "$(PCRE)" ] || \
	tar --bzip2 --get < "$(PCRE).tar.bz2"
	cd "$(PCRE)" && \
	./configure --prefix=/usr --enable-pcre16 --enable-pcre32 --enable-jit \
	    --enable-utf --enable-unicode-properties && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 LICENCE "$(MNT)"/usr/share/licenses/pcre/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

