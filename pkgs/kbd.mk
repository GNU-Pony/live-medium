# GPL
KBD = kbd-$(KBD_VERSION)
CLEAN_DIR += "$(KBD)"
packages: kbd
kbd:
	[ -f "$(KBD).tar.gz" ] || \
	wget "ftp://ftp.altlinux.org/pub/people/legion/kbd/$(KBD).tar.gz"
	[ -d "$(KBD)" ] || \
	tar --gzip --get < "$(KBD).tar.gz"
	cd "$(KBD)" && \
	mv data/keymaps/i386/qwertz/cz{,-qwertz}.map && \
	mv data/keymaps/i386/olpc/es{,-olpc}.map && \
	mv data/keymaps/i386/olpc/pt{,-olpc}.map && \
	mv data/keymaps/i386/dvorak/no{,-dvorak}.map && \
	mv data/keymaps/i386/fgGIod/trf{,-fgGIod}.map && \
	mv data/keymaps/i386/colemak/{en-latin9,colemak}.map && \
	patch -Np1 -i ../patches/fix-keymap-loading-1.15.5.patch && \
	./configure --prefix=/usr --datadir=/usr/share/kbd --mandir=/usr/share/man && \
	make KEYCODES_PROGS=yes RESIZECONS_PROGS=yes && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make KEYCODES_PROGS=yes RESIZECONS_PROGS=yes DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

