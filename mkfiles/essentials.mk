essentials: gnupony-filesystem gnupony-files


# /boot is symlinked to / in the live-medium so that /boot and /
# can be the same partition will still having a /boot directory
gnupony-filesystem:
	PATH="$$(realpath ./tools):$${PATH}" ARCH="$(ARCH)" make -C mkfiles/filesystem DESTDIR="$(MNT)" BOOT=flat install


# Install GNU/Pony configurations
gnupony-files:
	cp confs/auth-group "$(MNT)"/etc/group
	cp confs/auth-gshadow "$(MNT)"/etc/gshadow
	chmod 600 "$(MNT)"/etc/gshadow
	cp confs/auth-shadow "$(MNT)"/etc/shadow
	chmod 600 "$(MNT)"/etc/shadow
	cp confs/auth-passwd "$(MNT)"/etc/passwd


# chown live medium, binaries must not be chown:ed as that removes the permissions 6000
chown-live:
	sudo find "$(MNT)"/boot/{syslinux,memtest86+} | while read file; do \
	    echo 'chown -h root:root '"$$file"; \
	    sudo chown -h "$(root):$(root)" "$$file"; \
	done
	sudo chown -h "$(root):$(root)" "$(MNT)"/boot/initramfs-linux
	sudo chown -h "$(root):$(root)" "$(MNT)"/boot/vmlinuz-linux
	sudo chmod 755 "$(MNT)"


# Override configurations
conf-override:
	sudo cp -f confs/rc.conf "$(MNT)"/etc/rc.conf

# Create users
create-users:
	cat confs/create-users | sudo sh -c 'PATH=$(PATH) chroot "$(MNT)" /bin/bash'

