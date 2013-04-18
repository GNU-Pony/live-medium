# GPL
BASH_MINOR = $(shell echo $(BASH_VERSION) | cut -d . -f 1,2)
BASH_PATCH = $(shell echo $(BASH_VERSION) | cut -d . -f 3)
BASH = bash-$(BASH_MINOR)
BASH_ = $(shell echo bash$(BASH_MINOR) | tr -d .)
CLEAN_DIR += "$(BASH)"
packages: bash
bash:
	[ -f "$(BASH).tar.gz" ] || \
	wget "http://ftp.gnu.org/gnu/bash/$(BASH).tar.gz"
	[ -d "$(BASH)" ] || \
	tar --gzip --get < "$(BASH).tar.gz"
	if [ ! $(BASH_PATCH) = 0 ]; then \
	for (( p=1; p<=$(BASH_PATCH); p++ )); do \
	    [ -f "$(BASH_)-$$(printf "%03d" $$p)" ] || \
                wget "http://ftp.gnu.org/gnu/bash/$(BASH)-patches/$(BASH_)-$$(printf "%03d" $$p)" || exit 1; \
	done; fi && \
	cd "$(BASH)" && \
	if [ ! $(BASH_PATCH) = 0 ]; then \
	for (( p=1; p<=$(BASH_PATCH); p++ )); do \
	    patch -Np0 -i "../$(BASH_)-$$(printf "%03d" $$p)" || exit 1; \
	done; fi && \
	bashconfig=(-DDEFAULT_PATH_VALUE=\'\"/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\"\' \
	        -DSTANDARD_UTILS_PATH=\'\"/usr/bin:/bin:/usr/sbin:/sbin\"\' \
	        -DSYS_BASHRC=\'\"/etc/bash.bashrc\"\' \
	        -DSYS_BASH_LOGOUT=\'\"/etc/bash.bash_logout\"\') && \
	./configure --prefix=/usr --with-curses --enable-readline \
	        --without-bash-malloc --with-installed-readline && \
	make CFLAGS="${bashconfig[@]}" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -dm755  "$(MNT)"/bin && \
	sudo ln -sf ../usr/bin/bash "$(MNT)"/bin/bash && \
	sudo ln -sf ../usr/bin/bash "$(MNT)"/bin/sh && \
	sudo mkdir -p "$(MNT)"/etc/skel/ && \
	sudo install -m644 ../confs/system.bashrc "$(MNT)"/etc/bash.bashrc && \
	sudo install -m644 ../confs/system.bash_logout "$(MNT)"/etc/bash.bash_logout && \
	sudo install -m644 ../confs/user.bashrc "$(MNT)"/etc/skel/.bashrc && \
	sudo install -m644 ../confs/user.bash_profile "$(MNT)"/etc/skel/.bash_profile && \
	sudo install -m644 ../confs/user.bash_logout "$(MNT)"/etc/skel/.bash_logout && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

