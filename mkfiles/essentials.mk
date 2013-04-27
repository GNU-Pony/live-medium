essentials: gnupony-filesystem gnupony-files essential-logs


# /boot is symlinked to / in the live-medium so that /boot and /
# can be the same partition will still having a /boot directory
gnupony-filesystem:
	mkdir -p "$(MNT)"/bin
	ln -sf . "$(MNT)"/boot || true
	mkdir -p "$(MNT)"/dev/shm
	mkdir -p "$(MNT)"/etc/opt
	mkdir -p "$(MNT)"/etc/skel
	mkdir -p "$(MNT)"/etc/profile.d
	mkdir -p "$(MNT)"/etc/ld.so.conf.d
	mkdir -p "$(MNT)"/home
	mkdir -p "$(MNT)"/info
	ln -sf usr/lib "$(MNT)"/lib
	[ ! "$(ARCH)" = "x86_64" ] || ln -sf usr/lib "$(MNT)"/lib64
	mkdir -p "$(MNT)"/media
	mkdir -p "$(MNT)"/mnt
	mkdir -p "$(MNT)"/opt
	mkdir -p "$(MNT)"/proc
	chmod 555 "$(MNT)"/proc
	mkdir -p "$(MNT)"/root
	chmod 750 "$(MNT)"/root
	mkdir -p "$(MNT)"/run
	mkdir -p "$(MNT)"/sbin
	mkdir -p "$(MNT)"/share
	chmod 1777 "$(MNT)"/share
	mkdir -p "$(MNT)"/srv
	mkdir -p "$(MNT)"/srv/db
	mkdir -p "$(MNT)"/srv/ftp
	mkdir -p "$(MNT)"/srv/http
	mkdir -p "$(MNT)"/sys
	chmod 555 "$(MNT)"/sys
	mkdir -p "$(MNT)"/tmp
	chmod 1777 "$(MNT)"/tmp
	mkdir -p "$(MNT)"/usr/bin
	ln -sf bin "$(MNT)"/usr/games
	mkdir -p "$(MNT)"/usr/doc
	mkdir -p "$(MNT)"/usr/lib
	mkdir -p "$(MNT)"/usr/lib/pkgconfig
	mkdir -p "$(MNT)"/usr/libexec
	mkdir -p "$(MNT)"/usr/libmulti
	[ ! "$(ARCH)" = "x86_64" ] || ln -sf lib "$(MNT)"/usr/lib64
	mkdir -p "$(MNT)"/usr/sbin
	mkdir -p "$(MNT)"/usr/share/dict
	ln -sf ../doc "$(MNT)"/usr/share/doc
	mkdir -p "$(MNT)"/usr/share/man
	mkdir -p "$(MNT)"/usr/share/man/man{1..8}
	mkdir -p "$(MNT)"/usr/share/info
	mkdir -p "$(MNT)"/usr/share/misc
	mkdir -p "$(MNT)"/usr/share/licenses
	mkdir -p "$(MNT)"/usr/share/changelogs
	mkdir -p "$(MNT)"/usr/src
	mkdir -p "$(MNT)"/usr/local/bin
	mkdir -p "$(MNT)"/usr/local/doc
	mkdir -p "$(MNT)"/usr/local/etc
	ln -sf bin "$(MNT)"/usr/local/games
	mkdir -p "$(MNT)"/usr/local/include
	mkdir -p "$(MNT)"/usr/local/lib
	mkdir -p "$(MNT)"/usr/local/libexec
	mkdir -p "$(MNT)"/usr/local/libmulti
	ln -sf ../share/info "$(MNT)"/usr/local/info
	ln -sf ../share/man "$(MNT)"/usr/local/man
	mkdir -p "$(MNT)"/usr/local/sbin
	mkdir -p "$(MNT)"/usr/local/share
	mkdir -p "$(MNT)"/usr/local/share/licenses
	mkdir -p "$(MNT)"/usr/local/share/changelogs
	ln -sf ../doc "$(MNT)"/usr/local/share/doc
	ln -sf ../../share/man "$(MNT)"/usr/local/share/man
	ln -sf ../../share/info "$(MNT)"/usr/local/share/info
	mkdir -p "$(MNT)"/usr/local/src
	mkdir -p "$(MNT)"/var/cache
	mkdir -p "$(MNT)"/var/empty
	mkdir -p "$(MNT)"/var/games
	chmod 755 "$(MNT)"/var/games
	mkdir -p "$(MNT)"/var/lib
	mkdir -p "$(MNT)"/var/local/cache
	mkdir -p "$(MNT)"/var/local/games
	mkdir -p "$(MNT)"/var/local/lib
	mkdir -p "$(MNT)"/var/local/lock
	mkdir -p "$(MNT)"/var/local/spool
	mkdir -p "$(MNT)"/var/lock
	mkdir -p "$(MNT)"/var/log
	mkdir -p "$(MNT)"/var/opt
	mkdir -p "$(MNT)"/var/mail
	chmod 1777 "$(MNT)"/var/mail
	ln -sf ../run "$(MNT)"/var/run
	mkdir -p "$(MNT)"/var/spool
	ln -sf ../mail "$(MNT)"/var/spool/mail
	mkdir -p "$(MNT)"/var/tmp
	chmod 1777 "$(MNT)"/var/tmp


# Install essential logs
essential-logs:
	touch "$(MNT)"/var/log/{btmp,wtmp,lastlog}
	chmod 644 "$(MNT)"/var/log/lastlog
	chmod 644 "$(MNT)"/var/log/wtmp
	chmod 600 "$(MNT)"/var/log/btmp


# Install GNU/Pony configurations
gnupony-files:
	echo 0.0 > "$(MNT)"/etc/pony-release
	cp confs/os-release "$(MNT)"/etc/os-release
	echo 'include /etc/ld.so.conf.d/*.conf' > "$(MNT)"/etc/ld.so.conf
	cp confs/issue "$(MNT)"/etc/issue
	touch "$(MNT)"/etc/crypttab
	touch "$(MNT)"/etc/fstab
	ln -sf /proc/self/mounts "$(MNT)"/etc/mtab
	echo 'order hosts,bind' > "$(MNT)"/etc/host.conf
	echo 'multi on' >> "$(MNT)"/etc/host.conf
	echo '127.0.0.1 localhost.localdomain localhost canterlot' > "$(MNT)"/etc/hosts
	echo '::1 localhost.localdomain localhost canterlot' >> "$(MNT)"/etc/hosts
	touch "$(MNT)"/etc/motd
	echo 'hosts: files dns' > "$(MNT)"/etc/nsswitch.conf
	for x in network passwd group shadow publickey protocols services ethers rpc netgroup; \
	    do echo $$x': files dns' >> "$(MNT)"/etc/nsswitch.conf; done
	touch "$(MNT)"/etc/resolv.conf
	cp confs/securetty "$(MNT)"/etc/securetty
	echo '/bin/sh' > "$(MNT)"/etc/shells
	echo '/bin/bash' >> "$(MNT)"/etc/shells
	cp confs/locale.sh "$(MNT)"/etc/profile.d/locale.sh
	chmod a+x "$(MNT)"/etc/profile.d/locale.sh
	cp confs/profile "$(MNT)"/etc/profile
	cp confs/auth-group "$(MNT)"/etc/group
	cp confs/auth-gshadow "$(MNT)"/etc/gshadow
	chmod 600 "$(MNT)"/etc/gshadow
	cp confs/auth-shadow "$(MNT)"/etc/shadow
	chmod 600 "$(MNT)"/etc/shadow
	cp confs/auth-passwd "$(MNT)"/etc/passwd


# chown live medium
chown-live:
	sudo find "$(MNT)" | while read file; do \
	    echo 'chown -h root:root '"$$file"; \
	    sudo chown -h $(root):$(root) "$$file"; \
	done
	sudo chmod 755 "$(MNT)"
	sudo chgrp $(utmp) "$(MNT)"/var/log/lastlog
	sudo chgrp $(ftp) "$(MNT)"/srv/ftp
	sudo chgrp $(games) "$(MNT)"/var/games


# Override configurations
conf-override:
	sudo cp -f confs/rc.conf "$(MNT)"/etc/rc.conf
	sudo cp -f confs/issue "$(MNT)"/etc/issue
	sudo cp -f confs/fstab "$(MNT)"/etc/fstab
	sudo mkdir -p "$(MNT)"/etc/pam.d
	sudo cp -f confs/login "$(MNT)"/etc/pam.d/login


# Create users
create-users:
	cat confs/create-users | sudo chroot "$(MNT)"

