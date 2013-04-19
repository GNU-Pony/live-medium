# GPL2
# make dependencies: flex w3m docbook-xml>=4.4 docbook-xsl
PAM = Linux-PAM-$(PAM_VERSION)
CLEAN_DIR += "$(PAM)"
packages: pam
pam:
	[ -f "$(PAM).tar.bz2" ] || \
	wget "https://fedorahosted.org/releases/l/i/linux-pam/$(PAM).tar.bz2"
	[ -d "$(PAM)" ] || \
	tar --bzip2 --get < "$(PAM).tar.bz2"
	cd "$(PAM)" && \
	./configure --libdir=/usr/lib && \
	sed -i 's_mkdir -p $$(namespaceddir)_mkdir -p $$(DESTDIR)$$(namespaceddir)_g' \
	    modules/pam_namespace/Makefile && \
	make && \
	cd ..
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	cd "$(PAM)" && \
	sudo make DESTDIR="$(MNT)" SCONFIGDIR=/etc/security install && \
	sudo install -m644 ../confs/limits.conf "$(MNT)"/etc/security && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

