# BSD
LIBEDIT = libedit-$(LIBEDIT_VERSION)
CLEAN_DIR += "$(LIBEDIT)"
packages: libedit
libedit:
	[ -f "$(LIBEDIT).tar.gz" ] || \
	wget "http://www.thrysoee.dk/editline/$(LIBEDIT).tar.gz"
	[ -d "$(LIBEDIT)" ] || \
	tar --gzip --get < "$(LIBEDIT).tar.gz"
	cd "$(LIBEDIT)" && \
	./configure --prefix=/usr --enable-widec --enable-static=no && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix="$(MNT)"/usr install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/libedit/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

