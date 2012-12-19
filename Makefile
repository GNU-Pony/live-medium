ARCH = x86_64
KARCH = $(ARCH)

GNU_PONY_INITRAM = ../initram

KERNEL_VERSION = 3.7.1
KERNEL_VERSION_CAT = 3.0
KERNEL = linux-$(KERNEL_VERSION)
KERNEL_MIRROR = https://ftp.kernel.org/pub/linux
KERNEL_CONFIG = kernel.mini.config
# kernel.mini.config
# kernel.config

MEMTEST_VERSION = 4.20

USB_LABEL = GNU_PONY
USB_FS = ext2
MNT = /mnt
MBR = /usr/lib/syslinux/mbr.bin


all: kernel usb-init filesystem packages chmod


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
	make -C "$(KERNEL)" menuconfig

$(KERNEL)/vmlinux: #initramfs
	make -C "$(KERNEL)"

cpiolist:
	if [ ! -L "cpiolist" ]; then \
	    ln -s "$(GNU_PONY_INITRAM)/cpiolist" cpiolist; \
	fi

initramfs: cpiolist
	make -C "$(GNU_PONY_INITRAM)" KERNEL_SOURCE=$$(cd $(KERNEL) ; pwd)

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
	[ "$(DEVICE)" = "" ] || dd if=/dev/zero of="/dev/$(DEVICE)" bs=512 count=1

	[ "$(DEVICE)" = "" ] || fdisk "/dev/$(DEVICE)" <<.\
	o\
	n\
	p\
	1\
	\
	\
	a\
	1\
	w\
	.

	[ ! -d "$(MNT)" ] && mkdir -p "$(MNT)"
	[ "$(DEVICE)" = "" ] || mkfs -t "$(USB_FS)" -L "$(USB_LABEL)" "/dev/$(DEVICE)1"
	[ "$(DEVICE)" = "" ] || mount "/dev/$(DEVICE)1" "$(MNT)"
	[ "$(DEVICE)" = "" ] || extlinux --install "$(MNT)"
	[ "$(DEVICE)" = "" ] || dd if="$(MBR)" of="/dev/$(DEVICE)"
	mkdir "$(MNT)/syslinux"
	mkdir "$(MNT)/memtest86+"
	cp /usr/lib/syslinux/{*.{c32,com,0},memdisk} "$(MNT)/syslinux"
	cp ./memtest.bin "$(MNT)/memtest86+"
	cp ./syslinux.cfg "$(MNT)/syslinux"
	cp ./splash.png "$(MNT)/syslinux"
	cp "$$(realpath "./$(KERNEL)/arch/$(KARCH)/boot/bzImage")" "$(MNT)/vmlinuz-linux"
	mkdir -p "$(MNT)/usr/src/$(KERNEL)"
	cp "./$(KERNEL)/vmlinux" "$(MNT)/usr/src/$(KERNEL)/vmlinux"
	if [ -f initramfs-linux ]; then \
	    cp initramfs-linux "$(MNT)"; \
	else \
	    cp "./$(KERNEL)/usr/initramfs_data.cpio" "$(MNT)/initramfs-linux"; \
	fi
	[ "$(DEVICE)" = "" ] || umount "$(MNT)"


filesystem:
	mkdir -p "$(MNT)"/bin
	mkdir -p "$(MNT)"/boot
	mkdir -p "$(MNT)"/dev/shm
	mkdir -p "$(MNT)"/etc/opt
	mkdir -p "$(MNT)"/home
	mkdir -p "$(MNT)"/info
	ln -s usr/lib "$(MNT)"/lib
	[ "$(ARCH)" = "x86_64" ] && ln -s usr/lib "$(MNT)"/lib64
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
	ln -s bin "$(MNT)"/usr/games
	mkdir -p "$(MNT)"/usr/doc
	mkdir -p "$(MNT)"/usr/lib
	mkdir -p "$(MNT)"/usr/libexec
	mkdir -p "$(MNT)"/usr/libmulti
	mkdir -p "$(MNT)"/usr/sbin
	mkdir -p "$(MNT)"/usr/share/dict
	ln -s ../doc "$(MNT)"/usr/share/doc
	mkdir -p "$(MNT)"/usr/share/man
	mkdir -p "$(MNT)"/usr/share/info
	mkdir -p "$(MNT)"/usr/share/misc
	mkdir -p "$(MNT)"/usr/src
	mkdir -p "$(MNT)"/usr/local/bin
	mkdir -p "$(MNT)"/usr/local/doc
	mkdir -p "$(MNT)"/usr/local/etc
	ln -s bin "$(MNT)"/usr/local/games
	mkdir -p "$(MNT)"/usr/local/include
	mkdir -p "$(MNT)"/usr/local/lib
	mkdir -p "$(MNT)"/usr/local/libexec
	mkdir -p "$(MNT)"/usr/local/libmulti
	ln -s ../share/info "$(MNT)"/usr/local/info
	ln -s ../share/man "$(MNT)"/usr/local/man
	mkdir -p "$(MNT)"/usr/local/sbin
	mkdir -p "$(MNT)"/usr/local/share
	ln -s ../doc "$(MNT)"/usr/local/share/doc
	ln -s ../../share/man "$(MNT)"/usr/local/share/man
	ln -s ../../share/info "$(MNT)"/usr/local/share/info
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
	ln -s ../run "$(MNT)"/var/run
	mkdir -p "$(MNT)"/var/spool
	ln -s ../mail "$(MNT)"/var/spool/mail
	mkdir -p "$(MNT)"/var/tmp
	chmod 1777 "$(MNT)"/var/tmp


packages: coreutils glibc util-linux kbd


coreutils:
	wget "http://ftp.gnu.org/gnu/coreutils/coreutils-8.20.tar.xz"
	tar --xz --get < coreutils-8.20.tar.xz
	cd coreutils-8.20 && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || mount "/dev/$(DEVICE)1" "$(MNT)") && \
	make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || umount "$(MNT)") && \
	cd ..

glibc:
	wget "http://ftp.gnu.org/gnu/libc/glibc-2.16.0.tar.xz"
	tar --xz --get < glibc-2.16.0.tar.xz
	mkdir -p glibc-build
	cd glibc-build && \
	../glibc-2.16.0/configure --prefix="/usr" \
		--libdir="/usr/lib" \
		--libexecdir="/usr/libexec" \
		--with-headers="/usr/include" && \
	make && \
	([ "$(DEVICE)" = "" ] || mount "/dev/$(DEVICE)1" "$(MNT)") && \
	make install_root="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || umount "$(MNT)") && \
	cd ..

util-linux:
	wget "http://www.kernel.org/pub/linux/utils/util-linux/v2.22/util-linux-2.22.tar.xz"
	tar --xz --get < util-linux-2.22.tar.xz
	cd util-linux-2.22 && \
	./autogen.sh && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || mount "/dev/$(DEVICE)1" "$(MNT)") && \
	make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || umount "$(MNT)") && \
	cd ..

kbd:
	wget "http://www.kernel.org/pub/linux/utils/kbd/kbd-1.12.tar.gz"
	tar --gzip --get < kbd-1.12.tar.gz
	cd kbd-1.12 && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || mount "/dev/$(DEVICE)1" "$(MNT)"( && \
	make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || umount "$(MNT)"( && \
	cd ..


chmod:
	find "$(MNT)" | while read file; do \
	    sudo chown "root:root" "$$file"; \
	done


.PHONY: clean
clean:
	yes | rm -r linux-* memtest86+-* coreutils-* glibc-* \
	            util-linux-* kbd-* cpiolist *.bin \
	    || exit 0
	sudo make -C "$(GNU_PONY_INITRAM)" clean
