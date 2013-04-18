# BSD
OPENSSH = openssh-$(OPENSSH_VERSION)
CLEAN_DIR += "$(OPENSSH)"
packages: openssh
openssh:
	[ -f "$(OPENSSH).tar.gz" ] || \
	wget "ftp://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/$(OPENSSH).tar.gz"
	[ -d "$(OPENSSH)" ] || \
	tar --gzip --get < "$(OPENSSH).tar.gz"
	cd "$(OPENSSH)" && \
	./configure --prefix=/usr --libexecdir=/usr/lib/ssh --sysconfdir=/etc/ssh --with-ldns \
	        --with-libedit --with-ssl-engine --with-pam --with-privsep-user=nobody \
	        --with-kerberos5=/usr --with-xauth=/usr/bin/xauth --with-mantype=man \
	        --with-md5-passwords --with-pid-dir=/run && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm "$(MNT)"/usr/share/man/man1/slogin.1 && \
	sudo ln -sf ssh.1.gz "$(MNT)"/usr/share/man/man1/slogin.1.gz && \
	sudo install -Dm644 LICENCE "$(MNT)"/usr/share/licenses/openssh/LICENCE && \
	sudo install -Dm755 ../confs/sshd.close-sessions "$(MNT)"/etc/rc.d/functions.d/sshd-close-sessions && \
	sudo install -Dm644 ../confs/sshd.confd "$(MNT)"/etc/conf.d/sshd && \
	sudo install -Dm644 ../confs/sshd.pam "$(MNT)"/etc/pam.d/sshd && \
	sudo install -Dm755 ../confs/sshd "$(MNT)"/etc/rc.d/sshd && \
	sudo install -Dm755 contrib/findssl.sh "$(MNT)"/usr/bin/findssl.sh && \
	sudo install -Dm755 contrib/ssh-copy-id "$(MNT)"/usr/bin/ssh-copy-id && \
	sudo install -Dm644 contrib/ssh-copy-id.1 "$(MNT)"/usr/share/man/man1/ssh-copy-id.1 && \
	sudo sed -e '/^#ChallengeResponseAuthentication yes$$/c ChallengeResponseAuthentication no' \
	         -e '/^#PrintMotd yes$$/c PrintMotd no # pam does that' \
	         -e '/^#UsePAM no$$/c UsePAM yes' \
	         -i "$(MNT)"/etc/ssh/sshd_config && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

