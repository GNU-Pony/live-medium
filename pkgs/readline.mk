# GPL
READLINE_MINOR = $(shell echo $(READLINE_VERSION) | cut -d . -f 1,2)
READLINE_PATCH = $(shell echo $(READLINE_VERSION) | cut -d . -f 3)
READLINE = readline-$(READLINE_MINOR)
READLINE_ = $(shell echo readline$(READLINE_MINOR) | tr -d .)
CLEAN_DIR += "$(READLINE)"
packages: readline
readline:
	[ -f "$(READLINE).tar.gz" ] || \
	wget "http://ftp.gnu.org/gnu/readline/$(READLINE).tar.gz"
	[ -d "$(READLINE)" ] || \
	tar --gzip --get < "$(READLINE).tar.gz"
	if [ ! $(READLINE_PATCH) = 0 ]; then \
	for (( p=1; p<=$(READLINE_PATCH); p++ )); do \
	    [ -f "$(READLINE_)-$$(printf "%03d" $$p)" ] || \
            wget "http://ftp.gnu.org/gnu/readline/$(READLINE)-patches/$(READLINE_)-$$(printf "%03d" $$p)" \
	    || exit 1; \
	done; fi
	cd "$(READLINE)" && \
	if [ ! $(READLINE_PATCH) = 0 ]; then \
	for (( p=1; p<=$(READLINE_PATCH); p++ )); do \
	    [ -f "$(READLINE_)-$$(printf "%03d" $$p)" ] || \
            patch -Np0 -i ../"$(READLINE_)-$$(printf "%03d" $$p)" \
	    || exit 1; \
	done; fi && \
	sed -i 's_-Wl,-rpath,$$(libdir) __g' support/shobj-conf && \
	./configure --prefix=/usr && \
	make CFLAGS=-fPIC SHLIB_LIBS=-lncurses && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)/" install && \
	sudo install -Dm644 ../confs/inputrc "$(MNT)"/etc/inputrc && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

