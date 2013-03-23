# TODO do error check on gmp
ARCH = x86_64
KARCH = $(ARCH)
CHOST = $(ARCH)-unknown-linux-gnu

SYSVINIT_SIMPLIFY_WRITELOG = y
SYSVINIT_ANSI = n

GNU_PONY_INITRAM = ../initram

KERNEL_VERSION = 3.8.3
KERNEL_VERSION_CAT = 3.0
KERNEL = linux-$(KERNEL_VERSION)
KERNEL_MIRROR = https://ftp.kernel.org/pub/linux
KERNEL_CONFIG = kernelconf/kernel.mini.config
# kernel.mini.config
# kernel.config

MEMTEST_VERSION = 4.20

USB_LABEL = GNU_PONY
USB_FS = ext2
MNT = /mnt
MBR = /usr/lib/syslinux/mbr.bin
BOOT_SPLASH = ./boot/splash.png
BOOT_CONFIG = ./boot/syslinux.cfg

TAR_FILE = ../live-usb-files.tar
CPIO_FILE = ../live-usb-files.cpio

CLEAN_DIR =
ARCH_PACKAGE = filesystem linux linux-api-headers linux-firmware

include versions.mk

temp-default: validate-non-root filesystem arch-packages packages logs chown-usb tar-usb
all: validate-non-root kernel usb-init filesystem arch-packages packages logs chown-usb

validate-non-root:
	[ ! "$$UID" = 0 ]

validate-device:
	if ([ "$(DEVICE)" = "" ] && [ "$(DEVICELESS)" = "y" ]); then \
	    echo -e '\e[01;33mDeviceless installation\e[21;39m'; \
	else \
	    ([ -f "/dev/$(DEVICE)" ] &&  echo -e '\e[01;32mDEVICE ok\e[21;39m') \
	                             || (echo -e '\e[01;31mno DEVICE\e[21;39m' ; exit 1); \
	fi


kernel: $(KERNEL)/.config \
	$(KERNEL)/vmlinux

$(KERNEL).tar.xz:
	wget '$(KERNEL_MIRROR)/kernel/v$(KERNEL_VERSION_CAT)/$(KERNEL).tar.xz'

$(KERNEL): $(KERNEL).tar.xz
	tar --get --xz < "$(KERNEL).tar.xz"

$(KERNEL)/.config: $(KERNEL)
	if [ ! -f "$(KERNEL)/.config" ]; then \
	    cp "$(KERNEL_CONFIG)" "$(KERNEL)/.config"; \
	fi
	make -C "$(KERNEL)" prepare
	make -C "$(KERNEL)" menuconfig
	yes "" | make -C "$(KERNEL)" config > /dev/null

$(KERNEL)/vmlinux: #initramfs
	make -C "$(KERNEL)"

cpiolist:
	if [ ! -L "cpiolist" ]; then \
	    ln -s "$(GNU_PONY_INITRAM)/cpiolist" cpiolist; \
	fi

initramfs: cpiolist
	sudo make -C "$(GNU_PONY_INITRAM)" KERNEL_SOURCE=$$(cd $(KERNEL) ; pwd)

initramfs-linux: initramfs
	make -B update-init

update-init:
	"linux-$(KERNEL_VERSION)/usr/gen_init_cpio" cpiolist | xz -e9 > initramfs-linux


memtest: memtest.bin
memtest.bin:
	wget "http://www.memtest.org/download/$(MEMTEST_VERSION)/memtest86+-$(MEMTEST_VERSION).tar.gz"
	tar --gzip --get < "memtest86+-$(MEMTEST_VERSION).tar.gz"
	make -C "memtest86+-$(MEMTEST_VERSION)"
	cp "memtest86+-$(MEMTEST_VERSION)/memtest.bin" .


usb-init: memtest.bin validate-device
	[ "$(DEVICELESS)" = "y" ] || \
	[ "$(DEVICE)" = "" ] || sudo dd if=/dev/zero of="/dev/$(DEVICE)" bs=512 count=1
	[ "$(DEVICELESS)" = "y" ] || \
	[ "$(DEVICE)" = "" ] || ( echo -e 'o\nn\np\n1\n\n\na\n1\nw\n' | sudo fdisk "/dev/$(DEVICE)" )

	[ -d "$(MNT)" ] || mkdir -p "$(MNT)"
	[ "$(DEVICELESS)" = "y" ] || ( \
	( [ "$(DEVICE)" = "" ] || sudo mkfs -t "$(USB_FS)" -L "$(USB_LABEL)" "/dev/$(DEVICE)1" ) && \
	( [ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)" ) && \
	( [ "$(DEVICE)" = "" ] || sudo chmod 777 "$(MNT)" ) && \
	( [ "$(DEVICE)" = "" ] || sudo extlinux --install "$(MNT)" ) && \
	( [ "$(DEVICE)" = "" ] || sudo dd if="$(MBR)" of="/dev/$(DEVICE)" ) \
	)
	mkdir -p "$(MNT)/syslinux"
	mkdir -p "$(MNT)/memtest86+"
	cp /usr/lib/syslinux/{*.{c32,com,0},memdisk} "$(MNT)/syslinux"
	cp ./memtest.bin "$(MNT)/memtest86+"
	cp "$(BOOT_CONFIG)" "$(MNT)/syslinux/syslinux.cfg"
	cp "$(BOOT_SPLASH)" "$(MNT)/syslinux/splash.png"
	cp "$$(realpath "./$(KERNEL)/arch/$(KARCH)/boot/bzImage")" "$(MNT)/vmlinuz-linux"
	mkdir -p "$(MNT)/usr/src/$(KERNEL)"
	cp "./$(KERNEL)/vmlinux" "$(MNT)/usr/src/$(KERNEL)/vmlinux"
	if [ -f initramfs-linux ]; then \
	    cp initramfs-linux "$(MNT)"; \
	else \
	    cp "./$(KERNEL)/usr/initramfs_data.cpio" "$(MNT)/initramfs-linux"; \
	fi
	[ "$(DEVICELESS)" = "y" ] || [ "$(DEVICE)" = "" ] || sudo umount "$(MNT)"


filesystem:
	mkdir -p "$(MNT)"/bin
	mkdir -p "$(MNT)"/boot
	mkdir -p "$(MNT)"/dev/shm
	mkdir -p "$(MNT)"/etc/opt
	mkdir -p "$(MNT)"/home
	mkdir -p "$(MNT)"/info
	ln -sf usr/lib "$(MNT)"/lib
	[ ! "$(ARCH)" = "x86_64" ] || ln -sf usr/lib "$(MNT)"/lib64
	mkdir -p "$(MNT)"/media
	mkdir -p "$(MNT)"/mnt
	mkdir -p "$(MNT)"/opt
	mkdir -p "$(MNT)"/proc
	mkdir -p "$(MNT)"/root
	mkdir -p "$(MNT)"/run
	mkdir -p "$(MNT)"/sbin
	mkdir -p "$(MNT)"/share
	chmod 1777 "$(MNT)"/share
	mkdir -p "$(MNT)"/sys
	mkdir -p "$(MNT)"/tmp
	chmod 1777 "$(MNT)"/tmp
	mkdir -p "$(MNT)"/usr/bin
	ln -sf bin "$(MNT)"/usr/games
	mkdir -p "$(MNT)"/usr/doc
	mkdir -p "$(MNT)"/usr/lib
	mkdir -p "$(MNT)"/usr/libexec
	mkdir -p "$(MNT)"/usr/libmulti
	[ ! "$(ARCH)" = "x86_64" ] || ln -sf lib "$(MNT)"/usr/lib64
	mkdir -p "$(MNT)"/usr/sbin
	mkdir -p "$(MNT)"/usr/share/dict
	ln -sf ../doc "$(MNT)"/usr/share/doc
	mkdir -p "$(MNT)"/usr/share/man
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
	ln -sf ../run "$(MNT)"/var/run
	mkdir -p "$(MNT)"/var/spool
	ln -sf ../mail "$(MNT)"/var/spool/mail
	mkdir -p "$(MNT)"/var/tmp
	chmod 1777 "$(MNT)"/var/tmp

logs:
	touch "$(MNT)"/var/log/{btmp,wtmp,lastlog}
	chmod 644 "$(MNT)"/var/log/lastlog
	chmod 644 "$(MNT)"/var/log/wtmp
	chmod 600 "$(MNT)"/var/log/btmp

chown-usb:
	sudo find "$(MNT)" | while read file; do \
	    echo 'chown root:root '"$$file"; \
	    sudo chown "root:root" "$$file"; \
	done
	sudo chmod 755 "$(MNT)"
	sudo chgrp utmp "$(MNT)"/var/log/lastlog


# This is used to copy files via Arch Linux's pacman, so that package inclusion testing can be done easier
arch-packages:
	sudo pacman -Ql $(ARCH_PACKAGE) | \
	        cut -d ' ' -f 2 | grep    '/$$' | while read f; do \
	            echo "mkdir -p $(MNT)$$f"; \
	            sudo mkdir -p "$(MNT)$$f"; \
	        done
	sudo pacman -Ql $(ARCH_PACKAGE) | \
	        cut -d ' ' -f 2 | grep -v '/$$' | while read f; do \
	            echo "cp $$f => $(MNT)$$f"; \
	            [ -e "$(MNT)$$f" ] || \
	                sudo cp "$$f" "$(MNT)$$f"; \
	        done

# Create a tar with all files
tar-usb:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	sudo tar --create > "$(TAR_FILE)" \
	    $$(sudo find . | sed -e 's_^\./__' | cut -d / -f 1 | uniq | sort | uniq)

# Create a cpio with all files
cpio-usb:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	sudo find . | sed -e 's_^\./__' | cut -d / -f 1 | uniq | sort | uniq | \
	    sudo cpio --create > "$(CPIO_FILE)"


include pkgs/acl.mk
include pkgs/attr.mk
include pkgs/cracklib.mk
include pkgs/expat.mk
include pkgs/file.mk
include pkgs/hwids.mk
include pkgs/less.mk
include pkgs/libcap.mk
include pkgs/libgpg-error.mk
include pkgs/libnl.mk
include pkgs/libssh2.mk
include pkgs/libusbx.mk
include pkgs/ncurses.mk
include pkgs/netcfg.mk
include pkgs/pcre.mk
include pkgs/popt.mk
include pkgs/sysfsutils.mk
include pkgs/xz.mk
include pkgs/zlib.mk
include pkgs/ldns.mk
include pkgs/keyutils.mk
include pkgs/which.mk
include pkgs/tar.mk
include pkgs/sed.mk
include pkgs/nano.mk
include pkgs/coreutils.mk
include pkgs/db.mk
include pkgs/findutils.mk
include pkgs/gawk.mk
include pkgs/gettext.mk
include pkgs/gmp.mk
include pkgs/libffi.mk
include pkgs/libgcrypt.mk
include pkgs/bzip2.mk
include pkgs/gdbm.mk
include pkgs/glib2.mk
include pkgs/grep.mk
include pkgs/gzip.mk
include pkgs/iproute2.mk
include pkgs/texinfo.mk
include pkgs/sysvinit.mk
include pkgs/openssl.mk
include pkgs/libtirpc.mk
include pkgs/libpcap.mk
include pkgs/libgssglue.mk
include pkgs/readline.mk
include pkgs/kmod.mk
include pkgs/e2fsprogs.mk
include pkgs/bash.mk
include pkgs/libsasl.mk
include pkgs/gcc-libs.mk
include pkgs/initscripts-fork.mk
include pkgs/curl.mk
include pkgs/iana-etc.mk
include pkgs/cryptsetup.mk
include pkgs/dbus.mk
include pkgs/dhcpcd.mk
include pkgs/libedit.mk
include pkgs/openssh.mk
include pkgs/perl.mk
include pkgs/krb5.mk
include pkgs/iputils.mk
include pkgs/openntpd.mk
include pkgs/inetutils.mk
include pkgs/libldap.mk
include pkgs/device-mapper.mk
include pkgs/systemd.mk
include pkgs/kbd.mk
include pkgs/glibc.mk
include pkgs/pam.mk
include pkgs/pam_unix.mk
include pkgs/util-linux.mk
include pkgs/shadow.mk
include pkgs/tzdata.mk
include pkgs/dnssec-anchors.mk



.PHONY: clean
clean:
	sudo rm -r $(CLEAN_DIR) cpiolist *.bin || true
	sudo make -C "$(GNU_PONY_INITRAM)" clean || true

.PHONY: clean-download
clean-download:
	rm -r *.{tar{,.gz,.bz2,.xz},tgz} || true
	rm -r {bash,readline}??-??? || true

.PHONY: clean-mnt
clean-mnt:
	if [ "$(DEVICELESS)" = "y" ] && [ ! "$(MNT)" = "" ]; then \
	    sudo rm -r "$(MNT)" && mkdir "$(MNT)"; \
	elif [ "$(DEVICELESS)" = "" ] && [ ! "$(MNT)" = "" ]; then \
	    cd "$(MNT)" && for f in $$(echo * .*); do \
	        if [ ! "$$f" = "." ] && [ ! "$$f" = ".." ] && \
	           [ ! "$$f" = "lost+found" ] ; then \
	               sudo rm -r "$$f"; \
	    fi; done; \
	fi


.PHONY: clean-mostly
clean-mostly: clean clean-mnt

.PHONY: clean-all
clean-all: clean clean-download clean-mnt

