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

COREUTILS_VERSION = 8.20
GLIBC_VERSION = 2.16.0
UTIL_LINUX_VERSION = 2.22
KBD_VERSION = 1.12
SYSVINIT_VERSION = 2.88

COREUTILS = coreutils-$(COREUTILS_VERSION)
GLIBC = glibc-$(GLIBC_VERSION)
UTIL_LINUX = util-linux-$(UTIL_LINUX_VERSION)
KBD = kbd-$(KBD_VERSION)
SYSVINIT = sysvinit-$(SYSVINIT_VERSION)dsf

USB_LABEL = GNU_PONY
USB_FS = ext2
MNT = /mnt
MBR = /usr/lib/syslinux/mbr.bin


all: validate-non-root kernel usb-init filesystem logs packages chown


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


packages: coreutils glibc util-linux kbd sysvinit



coreutils:
	[ -f "$(COREUTILS).tar.xz" ] || \
	wget "http://ftp.gnu.org/gnu/coreutils/$(COREUTILS).tar.xz"
	[ -d "$(COREUTILS)" ] || \
	tar --xz --get < "$(COREUTILS).tar.xz"
	cd "$(COREUTILS)" && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

glibc:
	[ -f "$(GLIBC).tar.xz" ] || \
	wget "http://ftp.gnu.org/gnu/libc/$(GLIBC).tar.xz"
	[ -d "$(GLIBC)" ] || \
	tar --xz --get < "$(GLIBC).tar.xz"
	mkdir -p "glibc-build"
	cd "glibc-build" && \
	"../$(GLIBC)/configure" \
	        --prefix="/usr" \
		--libdir="/usr/lib" \
		--libexecdir="/usr/libexec" \
		--with-headers="/usr/include" && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	make install_root="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

util-linux:
	[ -f "$(UTIL_LINUX).tar.xz" ] || \
	wget "http://www.kernel.org/pub/linux/utils/util-linux/v$(UTIL_LINUX_VERSION)/$(UTIL_LINUX).tar.xz"
	[ -d "$(UTIL_LINUX)" ] || \
	tar --xz --get < "$(UTIL_LINUX).tar.xz"
	cd "$(UTIL_LINUX)" && \
	./autogen.sh && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

kbd:
	[ -f "$(KBD).tar.gz" ] || \
	wget "http://www.kernel.org/pub/linux/utils/kbd/$(KBD).tar.gz"
	[ -d "$(KBD)" ] || \
	tar --gzip --get < "$(KBD).tar.gz"
	cd "$(KBD)" && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

sysvinit:
	[ -f "$(SYSVINIT).tar.bz2" ] || \
	wget "http://download.savannah.gnu.org/releases/sysvinit/$(SYSVINIT).tar.bz2"
	[ -d "$(SYSVINIT)" ] || \
	tar --bzip2 --get < "$(SYSVINIT).tar.bz2"
	pushd "$(SYSVINIT)" && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	mkdir -p "$(MNT)/__pony_temp__" && \
	make ROOT="$(MNT)/__pony_temp__" install && \
	cd "$(MNT)/__pony_temp__" && \
	rm bin/pidof && \
	ln -s ../sbin/killall5 bin/pidof && \
	rm bin/mountpoint \
	   sbin/sulogin \
	   usr/bin/{mesg,utmpdump,wall} \
	   usr/share/man/man?/{mesg,mountpoint,sulogin,utmpdump,wall}.? && \
	( \
	    find ./ | while read file; do \
	        if [ -d "$$file" ]; then \
	            echo 'moving directory '"$$file"; \
	            sudo mkdir -p ."$$file"; \
	        else \
	            echo 'moving file '"$$file"; \
	            sudo cp -d "$$file" ."$$file"; \
	        fi; \
	    done \
	) && \
	cd .. && \
	rm -r __pony_temp__ && \
	popd && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
# removed files are provided by util-linux, except for the corrected (made safer) link


chown:
	find "$(MNT)" | while read file; do \
	    echo 'chmod root:root '"$$file"; \
	    sudo chown "root:root" "$$file"; \
	done
	sudo chmod 755 "$(MNT)"
	sudo chgrp utmp "$(MNT)"/var/log/lastlog


tar:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	sudo tar --create $$(find .) > ../live-usb-files.tar

cpio:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	find . | sudo cpio --create > ../live-usb-files.cpio


.PHONY: clean
clean:
	yes | rm -r linux-* memtest86+-* coreutils-* glibc-* \
	            util-linux-* kbd-* sysvinit-* cpiolist *.bin \
	    || exit 0
	sudo make -C "$(GNU_PONY_INITRAM)" clean
