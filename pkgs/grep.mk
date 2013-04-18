# GPL3
GREP = grep-$(GREP_VERSION)
CLEAN_DIR += "$(GREP)"
packages: grep
grep:
	[ -f "$(GREP).tar.xz" ] || \
	wget "ftp://ftp.gnu.org/gnu/grep/$(GREP).tar.xz"
	[ -d "$(GREP)" ] || \
	tar --xz --get < "$(GREP).tar.xz"
	cd "$(GREP)" && \
	./configure --prefix=/usr --without-included-regex && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

