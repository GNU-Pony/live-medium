ARCH = i386  ## Fallback, select by running make with ARCH=yourarch and KARCH=yourkernelarch if it is different
KARCH = $(ARCH)

GNU_PONY_INITRAM = ../initram

KERNEL_VERSION = 3.7.1
KERNEL_VERSION_CAT = 3.0
KERNEL = linux-$(KERNEL_VERSION)
KERNEL_MIRROR = https://ftp.kernel.org/pub/linux

MEMTEST_VERSION = 4.20

USB_LABEL = GNU_PONY
USB_FS = ext2
MNT = /mnt
MBR = /usr/lib/syslinux/mbr.bin


all: kernel initramfs-linux usb-init #packages


validate-device:
	([ -f "/dev/$(DEVICE)" ] && echo 'DEVICE ok') || (echo -e '\e[1;31mno DEVICE\e[m' ; exit 1)


kernel: $(KERNEL)/.config \
	$(KERNEL)/vmlinux

$(KERNEL).tar.xz:
	wget '$(KERNEL_MIRROR)/kernel/v$(KERNEL_VERSION_CAT)/$(KERNEL).tar.xz'

$(KERNEL): $(KERNEL).tar.xz
	tar --get --xz < "$(KERNEL).tar.xz"

$(KERNEL)/.config: $(KERNEL)
	if [ ! -f "$(KERNEL)/.config" ]; then \
	    cp kernel.config "$(KERNEL)/.config"; \
	fi
	make -C "$(KERNEL)" menuconfig

$(KERNEL)/vmlinux: initramfs
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

memtest:
	wget "http://www.memtest.org/download/$(MEMTEST_VERSION)/memtest86+-$(MEMTEST_VERSION).tar.gz"
	tar --gzip --get < "memtest86+-$(MEMTEST_VERSION).tar.gz"
	make -C "memtest86+-$(MEMTEST_VERSION)"
	cp "memtest86+-$(MEMTEST_VERSION)/memtest.bin" .


usb-init: memtest validate-device
	dd if=/dev/zero of="/dev/$(DEVICE)" bs=512 count=1

	fdisk "/dev/$(DEVICE)" <<.\
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

	mkfs -t "$(USB_FS)" -L "$(USB_LABEL)" "/dev/$(DEVICE)1"
	mount "/dev/$(DEVICE)1" "$(MNT)"
	extlinux --install "$(MNT)"
	dd if="$(MBR)" of="/dev/$(DEVICE)"
	mkdir "$(MNT)/syslinux"
	mkdir "$(MNT)/memtest86+"
	cp /usr/lib/syslinux/{*.{c32,com,0},memdisk} "$(MNT)/syslinux"
	cp ./memtest.bin "$(MNT)/memtest86+"
	cp ./syslinux.cfg "$(MNT)/syslinux"
	cp ./splash.png "$(MNT)/syslinux"
	cp "./$(KERNEL)/arch/$(KARCH)/boot/bzImage" "$(MNT)/vmlinuz-linux"
	mkdir -p "$(MNT)/usr/src/$(KERNEL)"
	cp "./$(KERNEL)/vmlinux" "$(MNT)/usr/src/$(KERNEL)/vmlinux"
	cp initramfs-linux "$(MNT)"
	umount "$(MNT)"


packages: coreutils glibc util-linux kbd


coreutils:
	wget "http://ftp.gnu.org/gnu/coreutils/coreutils-8.20.tar.xz"
	tar --xz --get < coreutils-8.20.tar.xz
	cd coreutils-8.20 && \
	./configure && \
	make && \
	mount "/dev/$(DEVICE)1" "$(MNT)" && \
	make DESTDIR="$(MNT)" install && \
	umount "$(MNT)" && \
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
	mount "/dev/$(DEVICE)1" "$(MNT)" && \
	make install_root="$(MNT)" install && \
	umount "$(MNT)" && \
	cd ..

util-linux:
	wget "http://www.kernel.org/pub/linux/utils/util-linux/v2.22/util-linux-2.22.tar.xz"
	tar --xz --get < util-linux-2.22.tar.xz
	cd util-linux-2.22 && \
	./autogen.sh && \
	./configure && \
	make && \
	mount "/dev/$(DEVICE)1" "$(MNT)" && \
	make DESTDIR="$(MNT)" install && \
	umount "$(MNT)" && \
	cd ..

kbd:
	wget "http://www.kernel.org/pub/linux/utils/kbd/kbd-1.12.tar.gz"
	tar --gzip --get < kbd-1.12.tar.gz
	cd kbd-1.12 && \
	./configure && \
	make && \
	mount "/dev/$(DEVICE)1" "$(MNT)" && \
	make DESTDIR="$(MNT)" install && \
	umount "$(MNT)" && \
	cd ..


.PHONY: clean
clean:
	yes | rm -r linux-* memtest86+-* coreutils-* glibc-* \
	            util-linux-* kbd-* cpiolist *.bin \
	    || exit 0
	sudo make -C "$(GNU_PONY_INITRAM)" clean

