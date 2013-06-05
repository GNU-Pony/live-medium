essentials: gnupony-filesystem gnupony-files


# /boot is symlinked to / in the live-medium so that /boot and /
# can be the same partition will still having a /boot directory
gnupony-filesystem:
	PATH="$$(realpath ./tools):$${PATH}" ARCH="$(ARCH)" make -C mkfiles/filesystem DESTDIR="$(MNT)" install


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


# Override configurations
conf-override:
	sudo cp -f confs/rc.conf "$(MNT)"/etc/rc.conf
	sudo cp -f confs/issue "$(MNT)"/etc/issue
	sudo cp -f confs/fstab "$(MNT)"/etc/fstab
	sudo mkdir -p "$(MNT)"/etc/pam.d
	sudo cp -f confs/login "$(MNT)"/etc/pam.d/login


# Create users
create-users:
	cat confs/create-users | sudo sh -c 'PATH=$(PATH) chroot "$(MNT)" /bin/bash'

