# GPL3
COREUTILS = coreutils-$(COREUTILS_VERSION)
CLEAN_DIR += "$(COREUTILS)"
packages: coreutils
coreutils:
	[ -f "$(COREUTILS).tar.xz" ] || \
	wget "http://ftp.gnu.org/gnu/coreutils/$(COREUTILS).tar.xz"
	[ -d "$(COREUTILS)" ] || \
	tar --xz --get < "$(COREUTILS).tar.xz"
	cd "$(COREUTILS)" && \
	./configure --prefix=/usr --libexecdir=/usr/libexec \
	        --enable-no-install-program=groups,hostname,kill,uptime && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	fhs=('cat' 'chgrp' 'chmod' 'chown' 'cp' 'date' 'dd' 'df' 'echo' 'false' 'ln' \
	     'ls' 'mkdir' 'mknod' 'mv' 'pwd' 'rm' 'rmdir' 'stty' 'sync' 'true' 'uname') && \
	for c in $${fhs[@]}; do  sudo ln -s ../usr/bin/$$c "$(MNT)"/bin/$$c;  done && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

