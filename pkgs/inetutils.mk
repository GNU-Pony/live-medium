# GPL3
INETUTILS = inetutils-$(INETUTILS_VERSION)
CLEAN_DIR += "$(INETUTILS)"
packages: inetutils
inetutils:
	[ -f "$(INETUTILS).tar.gz" ] || \
	wget "http://ftp.gnu.org/gnu/inetutils/$(INETUTILS).tar.gz"
	[ -d "$(INETUTILS)" ] || \
	tar --gzip --get < "$(INETUTILS).tar.gz"
	cd "$(INETUTILS)" && \
	sed -i 's#_GL_WARN_ON_USE (gets#//_GL_WARN_ON_USE (gets#' lib/stdio.in.h && \
	./configure --prefix=/usr --libexec=/usr/sbin --localstatedir=/var --sysconfdir=/etc \
	        --mandir=/usr/share/man --infodir=/usr/share/info --without-wrap --with-pam \
	        --enable-ftp --enable-ftpd --enable-telnet --enable-telnetd --enable-talk --enable-talkd \
	        --enable-rlogin --enable-rlogind --enable-rsh --enable-rshd --enable-rcp --enable-hostname \
	        --disable-rexec --disable-rexecd --disable-tftp --disable-tftpd --disable-ping \
	        --disable-ping6 --disable-logger --disable-syslogd --disable-inetd --disable-whois \
	        --disable-uucpd --disable-ifconfig --disable-traceroute && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	sudo ln -sf /usr/bin/hostname "$(MNT)"/bin/hostname && \
	sudo install -D -m755 ../confs/ftpd.rc "$(MNT)"/etc/rc.d/ftpd && \
	sudo install -D -m644 ../confs/ftpd.conf "$(MNT)"/etc/conf.d/ftpd && \
	sudo install -D -m644 ../confs/telnet.xinetd "$(MNT)"/etc/xinetd.d/telnet && \
	sudo install -D -m644 ../confs/talk.xinetd "$(MNT)"/etc/xinetd.d/talk && \
	sudo install -D -m644 ../confs/rlogin.xinetd "$(MNT)"/etc/xinetd.d/rlogin && \
	sudo install -D -m644 ../confs/rsh.xinetd "$(MNT)"/etc/xinetd.d/rsh && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

