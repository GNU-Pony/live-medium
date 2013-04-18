# GPL2
# make dependencies: flex w3m docbook-xml>=4.4 docbook-xsl
PAM_UNIX = pam_unix2-$(PAM_UNIX_VERSION)
CLEAN_DIR += "$(PAM_UNIX)"
packages: pam_unix
pam_unix:
	[ -f "$(PAM_UNIX).tar.bz2" ] || \
	wget "ftp://ftp.archlinux.org/other/pam_unix2/$(PAM_UNIX).tar.bz2"
	[ -d "$(PAM_UNIX)" ] || \
	tar --bzip2 --get < "$(PAM_UNIX).tar.bz2"
	cd "$(PAM_UNIX)" && \
	patch -Np1 -i ../patches/pam_unix2-glibc216.patch && \
	./configure --libdir=/usr/lib && \
	make && \
	cd ..
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	cd "$(PAM_UNIX)" && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo sed -i 's|# End of file||' "$(MNT)"/etc/security/limits.conf && \
	sudo sh -c 'echo "*               -       rtprio          0" >> $(MNT)/etc/security/limits.conf' && \
	sudo sh -c 'echo "*               -       nice            0" >> $(MNT)/etc/security/limits.conf' && \
	sudo sh -c 'echo "@audio          -       rtprio          65" >> $(MNT)/etc/security/limits.conf' && \
	sudo sh -c 'echo "@audio          -       nice           -10" >> $(MNT)/etc/security/limits.conf' && \
	sudo sh -c 'echo "@audio          -       memlock         40000" >> $(MNT)/etc/security/limits.conf' && \
	sudo ln -sf pam_unix.so "$(MNT)"/usr/lib/security/pam_unix_acct.so && \
	sudo ln -sf pam_unix.so "$(MNT)"/usr/lib/security/pam_unix_auth.so && \
	sudo ln -sf pam_unix.so "$(MNT)"/usr/lib/security/pam_unix_passwd.so && \
	sudo ln -sf pam_unix.so "$(MNT)"/usr/lib/security/pam_unix_session.so && \
	sudo chmod +s "$(MNT)"/sbin/unix_chkpwd && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

