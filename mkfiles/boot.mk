cpiolist:
	if [ ! -L "cpiolist" ]; then \
	    ln -sf "$(GNU_PONY_INITRAM)"/cpiolist cpiolist; \
	fi

initramfs-linux: initramfs
	sudo make -C "$(GNU_PONY_INITRAM)" KERNEL_SOURCE=$$(cd $(KERNEL) ; pwd)
	make -B update-init

update-init:
	$(INITCPIO_COMPRESS) < "$(GNU_PONY_INITRAM)"/initramfs-linux > initramfs-linux


CLEAN_DIR += memtest86+-$(MEMTEST_VERSION)
memtest: memtest.bin
memtest.bin:
	[ -f memtest86+-$(MEMTEST_VERSION).tar.gz ] || \
	wget "http://www.memtest.org/download/$(MEMTEST_VERSION)/memtest86+-$(MEMTEST_VERSION).tar.gz"
	[ -d memtest86+-$(MEMTEST_VERSION) ] || \
	tar --gzip --get < "memtest86+-$(MEMTEST_VERSION).tar.gz"
	make -C "memtest86+-$(MEMTEST_VERSION)"
	cp "memtest86+-$(MEMTEST_VERSION)/memtest.bin" .


init-live: memtest.bin validate-device
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
	cp "$(SYSLINUX_DIR)"/{*.{c32,com,0},memdisk} "$(MNT)/syslinux"
	cp ./memtest.bin "$(MNT)/memtest86+"
	cp "$(BOOT_CONFIG)" "$(MNT)/syslinux/syslinux.cfg"
	sed -i 's/root=LABEL=GNU_PONY/root=LABEL=$(USB_LABEL)/g' "$(MNT)/syslinux/syslinux.cfg"
	cp "$(BOOT_SPLASH)" "$(MNT)/syslinux/splash.png"
	cp "$$(realpath "./$(KERNEL)/arch/$(KERNEL_ARCH)/boot/bzImage")" "$(MNT)/vmlinuz-linux"
	mkdir -p "$(MNT)/usr/src/$(KERNEL)"
	cp "./$(KERNEL)/vmlinux" "$(MNT)/usr/src/$(KERNEL)/vmlinux"
	if [ -f initramfs-linux ]; then \
	    cp initramfs-linux "$(MNT)"; \
	else \
	    cp "./$(KERNEL)/usr/initramfs_data.cpio" "$(MNT)/initramfs-linux"; \
	fi
	[ "$(DEVICELESS)" = "y" ] || [ "$(DEVICE)" = "" ] || sudo umount "$(MNT)"

