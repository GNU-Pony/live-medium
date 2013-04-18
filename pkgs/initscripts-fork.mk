# GPL2
INITSCRIPTS_FORK = initscripts-fork-$(INITSCRIPTS_FORK_VERSION)
CLEAN_DIR += "$(INITSCRIPTS_FORK)"
packages: initscripts-fork
initscripts-fork:
	[ -f "$(INITSCRIPTS_FORK).tar.bz2" ] || \
	wget "https://bitbucket.org/TZ86/initscripts-fork/get/$(INITSCRIPTS_FORK_VERSION).tar.bz2" \
	    -O "$(INITSCRIPTS_FORK).tar.bz2"
	[ -d "$(INITSCRIPTS_FORK)" ] || \
	(tar --bzip2 --get < "$(INITSCRIPTS_FORK).tar.bz2" && \
	    mv TZ86-initscripts-fork-* "$(INITSCRIPTS_FORK)") && \
	cd "$(INITSCRIPTS_FORK)" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sed -i 's_ln -s _ln -sf _g' Makefile && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

