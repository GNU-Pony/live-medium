# MIT
NCURSES = ncurses-$(NCURSES_VERSION)
CLEAN_DIR += "$(NCURSES)"
packages: ncurses
ncurses:
	[ -f "$(NCURSES).tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/ncurses/$(NCURSES).tar.gz"
	[ -d "$(NCURSES)" ] || \
	tar --gzip --get < "$(NCURSES).tar.gz"
	cd "$(NCURSES)" && \
	mkdir -p ncurses-build && \
	mkdir -p ncursesw-build && \
	cd ncursesw-build && \
	../configure --prefix=/usr --mandir=/usr/share/man \
	    --with-shared --with-normal --without-debug --without-ada \
	    --enable-widec --enable-pc-files && \
	make && \
	cd ../ncurses-build && \
	([ ! "$(ARCH)" = "x86_64" ] || export CONFIGFLAG="--with-chtype=long") && \
	../configure --prefix=/usr \
	    --with-shared --with-normal --without-debug --without-ada $$CONFIGFLAG && \
	make && \
	cd ../ncursesw-build && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make CF_MFLAGS="DESTDIR=$(MNT)" DESTDIR="$(MNT)" install && \
	for lib in ncurses form panel menu; do \
	    sudo sh -c 'echo "INPUT(-l$${lib}w)" > "$(MNT)"/usr/lib/lib$${lib}.so'; \
	    sudo ln -sf lib$${lib}w.a "$(MNT)"/usr/lib/lib$${lib}.a; \
	done && \
	sudo ln -sf libncurses++w.a "$(MNT)"/usr/lib/libncurses++.a && \
	for lib in ncurses ncurses++ form panel menu; do \
	    sudo ln -sf $${lib}w.pc "$(MNT)"/usr/lib/pkgconfig/$${lib}.pc; \
	done && \
	sudo sh -c 'echo "INPUT(-lncursesw)" > "$(MNT)"/usr/lib/libcursesw.so' && \
	sudo ln -sf libncurses.so "$(MNT)"/usr/lib/libcurses.so && \
	sudo ln -sf libncursesw.a "$(MNT)"/usr/lib/libcursesw.a && \
	sudo ln -sf libncurses.a "$(MNT)"/usr/lib/libcurses.a && \
	cd ../ncurses-build && \
	for lib in ncurses form panel menu; do \
	    sudo install -Dm755 lib/lib$${lib}.so.$(NCURSES_VERSION) \
	                        "$(MNT)"/usr/lib/lib$${lib}.so.$(NCURSES_VERSION); \
	    sudo ln -sf lib$${lib}.so.$(NCURSES_VERSION) \
	                "$(MNT)"/usr/lib/lib$${lib}.so.$$(echo $(NCURSES_VERSION) | cut -d . -f 1); \
	done && \
	cd .. && \
	sudo install -dm755 "$(MNT)"/usr/share/licenses/ncurses && \
	sudo sh -c 'grep -B 100 \$$Id README > "$(MNT)"/usr/share/licenses/ncurses/license.txt' && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

