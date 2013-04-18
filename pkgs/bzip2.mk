# custom (permissive free)
BZIP2 = bzip2-$(BZIP2_VERSION)
BZIP2_MAJOR = $(shell echo $(BZIP2_VERSION) | cut -d . -f 1)
BZIP2_MINOR = $(shell echo $(BZIP2_VERSION) | cut -d . -f 1,2)
CLEAN_DIR += "$(BZIP2)"
packages: bzip2
bzip2:
	[ -f "$(BZIP2).tar.gz" ] || \
	wget "http://www.bzip.org/$(BZIP2_VERSION)/$(BZIP2).tar.gz"
	[ -d "$(BZIP2)" ] || \
	tar --gzip --get < "$(BZIP2).tar.gz"
	cd "$(BZIP2)" && \
	sed -e 's/^CFLAGS=\(.*\)$$/CFLAGS=\1 \$$(BIGFILES)/' -i ./Makefile-libbz2_so && \
	patch -Np1 < ../patches/bzip2-1.0.4-bzip2recover.patch && \
	make -f Makefile-libbz2_so && \
	make bzip2 bzip2recover libbz2.a && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo install -dm755 "$(MNT)"/usr/{bin,lib,include,share/man/man1} && \
	sudo install -m755 bzip2-shared "$(MNT)"/usr/bin/bzip2 && \
	sudo install -m755 bzip2recover bzdiff bzgrep bzmore "$(MNT)"/usr/bin && \
	sudo ln -sf bzip2 "$(MNT)"/usr/bin/bunzip2 && \
	sudo ln -sf bzip2 "$(MNT)"/usr/bin/bzcat && \
	sudo install -m755 libbz2.so.$(BZIP2_VERSION) "$(MNT)"/usr/lib && \
	sudo ln -sf libbz2.so.$(BZIP2_VERSION) "$(MNT)"/usr/lib/libbz2.so && \
	sudo ln -sf libbz2.so.$(BZIP2_VERSION) "$(MNT)"/usr/lib/libbz2.so.$(BZIP2_MAJOR) && \
	sudo ln -sf libbz2.so.$(BZIP2_VERSION) "$(MNT)"/usr/lib/libbz2.so.$(BZIP2_MINOR) && \
	sudo install -m644 libbz2.a "$(MNT)"/usr/lib/libbz2.a && \
	sudo install -m644 bzlib.h "$(MNT)"/usr/include/ && \
	sudo install -m644 bzip2.1 "$(MNT)"/usr/share/man/man1/ && \
	sudo ln -sf bzip2.1 "$(MNT)"/usr/share/man/man1/bunzip2.1 && \
	sudo ln -sf bzip2.1 "$(MNT)"/usr/share/man/man1/bzcat.1 && \
	sudo ln -sf bzip2.1 "$(MNT)"/usr/share/man/man1/bzip2recover.1 && \
	sudo install -Dm644 LICENSE "$(MNT)"/usr/share/licenses/bzip2/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

