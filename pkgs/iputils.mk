# GPL, BSD
# makedependency: opensp, docbook2x
IPUTILS = iputils-s$(IPUTILS_VERSION)
CLEAN_DIR += "$(IPUTILS)"
packages: iputils
iputils:
	[ -f "$(IPUTILS).tar.bz2" ] || \
	wget "http://www.skbuff.net/iputils/$(IPUTILS).tar.bz2"
	[ -d "$(IPUTILS)" ] || \
	tar --bzip2 --get < "$(IPUTILS).tar.bz2"
	cd "$(IPUTILS)" && \
	ccoptopt="-O2 -pipe -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" && \
	make USE_GNUTLS=no CCOPTOPT="$$ccoptopt" && \
	cd doc && \
	for file in *.sgml; do \
	    xf=$${file/.sgml/.xml} && \
	    (osx -xlower -xno-nl-in-tag $$file > $$xf || true) && \
	    sed -i "s_<refname>\(.*\), \(.*\)</refname>_<refname>\1</refname>, <refname>\2</refname>_g" $$xf && \
	    docbook2man $$xf; \
	done && \
	cd .. && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo install -dm755 "$(MNT)"/usr/{bin,sbin} "$(MNT)"/bin && \
	sudo install -m755 arping clockdiff rarpd rdisc tftpd tracepath tracepath6 "$(MNT)"/usr/sbin/ && \
	sudo install -m755 ping{,6} "$(MNT)"/usr/bin/ && \
	sudo ln -sf /usr/bin/ping{,6}  "$(MNT)"/bin/ && \
	sudo install -dm755 "$(MNT)"/usr/share/man/man8 && \
	sudo install -m644 doc/{arping,clockdiff,ping,rarpd,rdisc,tftpd,tracepath}.8 \
	        "$(MNT)"/usr/share/man/man8/ && \
	sudo ln -sf ping.8.gz  "$(MNT)"/usr/share/man/man8/ping6.8.gz && \
	sudo ln -sf tracepath.8.gz "$(MNT)"/usr/share/man/man8/tracepath6.8.gz && \
	sudo install -dm755 "$(MNT)"/etc/xinetd.d/ && \
	sudo install -m644 ../confs/tftp.xinetd "$(MNT)"/etc/xinetd.d/tftp && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

