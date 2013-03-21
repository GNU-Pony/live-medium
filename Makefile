ARCH = x86_64
KARCH = $(ARCH)

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

COREUTILS_VERSION = 8.21
GLIBC_VERSION = 2.17
UTIL_LINUX_VERSION = 2.22.2
KBD_VERSION = 1.15.5
SYSVINIT_VERSION = 2.88
PAM_VERSION = 1.1.6

COREUTILS = coreutils-$(COREUTILS_VERSION)
GLIBC = glibc-$(GLIBC_VERSION)
UTIL_LINUX = util-linux-$(UTIL_LINUX_VERSION)
KBD = kbd-$(KBD_VERSION)
SYSVINIT = sysvinit-$(SYSVINIT_VERSION)dsf
PAM = Linux-PAM-$(PAM_VERSION)

USB_LABEL = GNU_PONY
USB_FS = ext2
MNT = /mnt
MBR = /usr/lib/syslinux/mbr.bin
BOOT_SPLASH = ./boot/splash.png
BOOT_CONFIG = ./boot/syslinux.cfg


MORE_PACKAGE = filesystem
MORE_PACKAGE += gcc-libs-multilib lib32-gcc-libs initscripts-fork linux linux-api-headers linux-firmware
MORE_PACKAGE += cryptsetup curl dbus device-mapper dhcpcd filesystem iana-etc inetutils iputils perl shadow systemd tzdata openssh openntpd dnssec-anchors krb5 libldap
MORE_PACKAGE += libtirpc


temp-default: validate-non-root filesystem more-packages working logs chown-usb
all: validate-non-root kernel usb-init filesystem packages logs chown-usb

packages: glibc util-linux kbd pam new working more-packages

new:
not-compiling: libtirpc
not-running: 

working: acl attr cracklib expat file hwids less libsasl libcap libnl libssh2 libusbx netcfg pcre popt sysfsutils xz ldns keyutils which tar nano coreutils db findutils gawk gettext gmp libffi libgcrypt zlib sed libgpg-error ncurses bzip2 gdbm glib2 grep gzip iproute2 texinfo openssl libpcap sysvinit libgssglue readline kmod e2fsprogs bash


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



glibc:
	export CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe --param=ssp-buffer-size=4" && \
	export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro" && \
	[ -f "$(GLIBC).tar.xz" ] || \
	wget "http://ftp.gnu.org/gnu/libc/$(GLIBC).tar.xz"
	[ -d "$(GLIBC)" ] || \
	tar --xz --get < "$(GLIBC).tar.xz"
	[ ! -d "glibc-build" ] || rm -r "glibc-build"
	mkdir "glibc-build"
	cd "$(GLIBC)" && patch -p1 -i ../patches/glibc-2.17-sync-with-linux37.patch && cd ..
	cd "glibc-build" && \
	unset LD_LIBRARY_PATH && \
	echo "slibdir=/usr/lib" >> configparms && \
	"../$(GLIBC)/configure" \
	        --prefix="/usr" \
		--libdir="/usr/lib" \
		--libexecdir="/usr/libexec" \
		--with-headers="/usr/include" \
	        --enable-add-ons=nptl,libidn \
	        --enable-obsolete-rpc \
	        --enable-kernel=2.6.32 \
	        --enable-bind-now --disable-profile \
	        --enable-stackguard-randomization \
	        --enable-multi-arch && \
	echo "build-programs=no" >> configparms && \
	make && \
	sed -i "/build-programs=/s#no#yes#" configparms && \
	echo "CC += -fstack-protector -D_FORTIFY_SOURCE=2" >> configparms && \
	echo "CXX += -fstack-protector -D_FORTIFY_SOURCE=2" >> configparms && \
	make && \
	sed -i '2,4d' configparms && \
	install -dm755 $(MNT)/etc && \
	touch $(MNT)/etc/ld.so.conf && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	make install_root="$(MNT)" install && \
	cd ..
	rm -f "$(MNT)"/etc/ld.so.{cache,conf}
	install -dm755 "$(MNT)"/usr/lib/{locale,systemd/system,tmpfiles.d}
	install -m644 "$(GLIBC)"/nscd/nscd.conf "$(MNT)"/etc/nscd.conf
	install -m644 nscd.service "$(MNT)"/usr/lib/systemd/system
	install -m644 nscd.tmpfiles "$(MNT)"/usr/lib/tmpfiles.d/nscd.conf
	install -m644 "$(GLIBC)"/posix/gai.conf "$(MNT)"/etc/gai.conf
	install -m755 locale-gen "$(MNT)"/usr/bin
	([ "$$(realpath "$(MNT)/sbin")" = "$$(realpath "$(MNT)/usr/bin")" ] || \
	        ln -sf ../../sbin/ldconfig "$(MNT)"/usr/bin/ldconfig)
	strip --strip-all \
	        "$(MNT)"/sbin/{ldconfig,sln} \
	        "$(MNT)"/usr/bin/{gencat,getconf,getent,iconv,locale,localedef} \
	        "$(MNT)"/usr/bin/{makedb,pcprofiledump,pldd,rpcgen,sprof} \
	        "$(MNT)"/usr/sbin/{iconvconfig,nscd}
	strip --strip-debug "$(MNT)"/usr/lib/*.a
	strip --strip-unneeded \
	        "$(MNT)"/usr/lib/{libanl,libBrokenLocale,libcidn,libcrypt}-*.so \
	        "$(MNT)"/usr/lib/libnss_{compat,db,dns,files,hesiod,nis,nisplus}-*.so \
	        "$(MNT)"/usr/lib/{libdl,libm,libnsl,libresolv,librt,libutil}-*.so \
	        "$(MNT)"/usr/lib/{libmemusage,libpcprofile,libSegFault}.so \
	        "$(MNT)"/usr/lib/{audit,gconv}/*.so
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")

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

pam:
	[ -f "$(PAM).tar.bz2" ] || \
	wget "https://fedorahosted.org/releases/l/i/linux-pam/$(PAM).tar.bz2"
	[ -d "$(PAM)" ] || \
	tar --bzip2 --get < "$(PAM).tar.bz2"
	cd "$(PAM)" && \
	./configure --libdir=/usr/lib && \
	sed -i 's_mkdir -p $$(namespaceddir)_mkdir -p $$(DESTDIR)$$(namespaceddir)_g' \
	    modules/pam_namespace/Makefile && \
	make && \
	make DESTDIR="$(MNT)" SCONFIGDIR=/etc/security install


# TODO : copying files installed with Arch Linux's pacman while no installation script has been made
more-packages:
	sudo pacman -Ql $(MORE_PACKAGE) | \
	        cut -d ' ' -f 2 | grep    '/$$' | while read f; do \
	            echo "mkdir -p $(MNT)$$f"; \
	            sudo mkdir -p "$(MNT)$$f"; \
	        done
	sudo pacman -Ql $(MORE_PACKAGE) | \
	        cut -d ' ' -f 2 | grep -v '/$$' | while read f; do \
	            echo "cp $$f => $(MNT)$$f"; \
	            [ -e "$(MNT)$$f" ] || \
	                sudo cp "$$f" "$(MNT)$$f"; \
	        done
	cd "$(MNT)" && sudo tar --create * > "../morefiles.tar" && cd ..


chown-usb:
	find "$(MNT)" | while read file; do \
	    echo 'chown root:root '"$$file"; \
	    sudo chown "root:root" "$$file"; \
	done
	sudo chmod 755 "$(MNT)"
	sudo chgrp utmp "$(MNT)"/var/log/lastlog


tar-usb:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	sudo tar --create $$(find .) > ../live-usb-files.tar

cpio-usb:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	find . | sudo cpio --create > ../live-usb-files.cpio


.PHONY: clean
clean:
	yes | rm -r linux-* memtest86+-* coreutils-* glibc-* \
	            util-linux-* kbd-* sysvinit-* cpiolist *.bin \
	    || exit 0
	sudo make -C "$(GNU_PONY_INITRAM)" clean


# LGPL
acl:
	[ -f "acl-2.2.51.src.tar.gz" ] || \
	wget "http://download.savannah.gnu.org/releases/acl/acl-2.2.51.src.tar.gz"
	[ -d "acl-2.2.51" ] || \
	tar --gzip --get < "acl-2.2.51.src.tar.gz"
	cd "acl-2.2.51" && \
	export INSTALL_USER=root INSTALL_GROUP=root && \
	./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/usr/lib && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DIST_ROOT="$(MNT)" install install-lib install-dev && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# LGPL
attr:
	[ -f "attr-2.4.46.src.tar.gz" ] || \
	wget "http://download.savannah.gnu.org/releases/attr/attr-2.4.46.src.tar.gz"
	[ -d "attr-2.4.46" ] || \
	tar --gzip --get < "attr-2.4.46.src.tar.gz"
	cd "attr-2.4.46" && \
	export INSTALL_USER=root INSTALL_GROUP=root && \
	./configure --prefix=/usr --libdir=/usr/lib --libexecdir=/usr/libexec && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DIST_ROOT="$(MNT)" install install-lib install-dev && \
	sudo rm -f "$(MNT)"/usr/lib/libattr.a && \
	sudo chmod 0755 "$(MNT)"/usr/lib/libattr.so.*.*.* && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
cracklib:
	[ -f "cracklib-2.8.22.src.tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/cracklib/cracklib-2.8.22.tar.gz"
	[ -d "cracklib-2.8.22" ] || \
	tar --gzip --get < "cracklib-2.8.22.tar.gz"
	cd "cracklib-2.8.22" && \
	./configure --prefix=/usr --without-python && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 dicts/cracklib-small "$(MNT)"/usr/share/dict/cracklib-small && \
	sudo sh ./util/cracklib-format dicts/cracklib-small | \
	    sudo sh ./util/cracklib-packer "$(MNT)"/usr/share/cracklib/pw_dict && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (permissive free)
expat:
	[ -f "expat-2.1.0.tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/expat/expat-2.1.0.tar.gz"
	[ -d "expat-2.1.0" ] || \
	tar --gzip --get < "expat-2.1.0.tar.gz"
	cd "expat-2.1.0" && \
	./configure --prefix=/usr --mandir=/usr/share/man && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/expat/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (permissive free)
file:
	[ -f "file-5.13.tar.gz" ] || \
	wget "ftp://ftp.astron.com/pub/file/file-5.13.tar.gz"
	[ -d "file-5.13" ] || \
	tar --gzip --get < "file-5.13.tar.gz"
	cd "file-5.13" && \
	./configure --prefix=/usr --datadir=/usr/share/file && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/file/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL2
hwids:
	[ -f "hwids-20130228.tar.gz" ] || \
	wget "https://github.com/gentoo/hwids/tarball/hwids-20130228" -O "hwids-20130228.tar.gz"
	[ -d "gentoo-hwids"* ] || \
	tar --gzip --get < "hwids-20130228.tar.gz"
	cd "gentoo-hwids"* && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	for ids in pci.ids usb.ids; do \
	    sudo install -Dm644 "$$ids" "$(MNT)/usr/share/hwdata/$${ids}"; \
	done && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
less:
	[ -f "less-451.tar.gz" ] || \
	wget "http://www.greenwoodsoftware.com/less/less-451.tar.gz"
	[ -d "less-451" ] || \
	tar --gzip --get < "less-451.tar.gz"
	cd "less-451" && \
	./configure --prefix=/usr --sysconfdir=/etc --with-regex=pcre && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix="$(MNT)"/usr install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL2
libcap:
	[ -f "libcap-2.22.tar.gz" ] || \
	wget "ftp://ftp.archlinux.org/other/libcap/libcap-2.22.tar.gz"
	[ -d "libcap-2.22" ] || \
	tar --gzip --get < "libcap-2.22.tar.gz"
	cd "libcap-2.22" && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix=/usr DESTDIR="$(MNT)" RAISE_SETFCAP=no install && \
	sudo chmod 755 "$(MNT)"/usr/lib/libcap.so.2.22 && \
	sudo rm "$(MNT)"/usr/lib/libcap.a && \
	sudo install -Dm644 pam_cap/capability.conf "$(MNT)"/usr/share/doc/libcap/capability.conf.example && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# LGPL
libgpg-error:
	[ -f "libgpg-error-1.11.tar.gz" ] || \
	wget "ftp://ftp.gnupg.org/gcrypt/libgpg-error/libgpg-error-1.11.tar.gz"
	[ -d "libgpg-error-1.11" ] || \
	tar --gzip --get < "libgpg-error-1.11.tar.gz"
	cd "libgpg-error-1.11" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
libnl:
	[ -f "libnl-3.2.21.tar.gz" ] || \
	wget "http://www.infradead.org/~tgr/libnl/files/libnl-3.2.21.tar.gz"
	[ -d "libnl-3.2.21" ] || \
	tar --gzip --get < "libnl-3.2.21.tar.gz"
	cd "libnl-3.2.21" && \
	./configure --prefix=/usr --sysconfdir=/etc --sbindir=/usr/bin --disable-static && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
libssh2:
	[ -f "libssh2-1.4.3.tar.gz" ] || \
	wget "http://www.libssh2.org/download/libssh2-1.4.3.tar.gz"
	[ -d "libssh2-1.4.3" ] || \
	tar --gzip --get < "libssh2-1.4.3.tar.gz"
	cd "libssh2-1.4.3" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/libssh2/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# LGPL
libusbx:
	[ -f "libusbx-1.0.14.tar.gz" ] || \
	wget "http://downloads.sourceforge.net/libusbx/libusbx-1.0.14.tar.bz2"
	[ -d "libusbx-1.0.14" ] || \
	tar --bzip2 --get < "libusbx-1.0.14.tar.bz2"
	cd "libusbx-1.0.14" && \
	./configure --prefix=/usr --disable-static && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# MIT
ncurses:
	[ -f "ncurses-5.9.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz"
	[ -d "ncurses-5.9" ] || \
	tar --gzip --get < "ncurses-5.9.tar.gz"
	cd "ncurses-5.9" && \
	mkdir -p ncurses-build && \
	mkdir -p ncursesw-build && \
	cd ncursesw-build && \
	../configure --prefix=/usr --mandir=/usr/share/man \
	    --with-shared --with-normal --without-debug --without-ada \
	    --enable-widec --enable-pc-files && \
	make && \
	cd ../ncurses-build && \
	([ ! "$(ARCH)" = "x86_64" ] || export CONFIGFLAG="--with-chtype=long") && \
	../configure --prefix=/usr \
	    --with-shared --with-normal --without-debug --without-ada $$CONFIGFLAG && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make CF_MFLAGS="$(MNT)" DESTDIR="$(MNT)" install && \
	for lib in ncurses form panel menu; do \
	    sudo sh -c 'echo "INPUT(-l$${lib}w)" > "$(MNT)"/usr/lib/lib$${lib}.so'; \
	    sudo ln -sf lib$${lib}w.a "$(MNT)"/usr/lib/lib$${lib}.a; \
	done && \
	sudo ln -sf libncurses++w.a "$(MNT)"/usr/lib/libncurses++.a && \
	for lib in ncurses ncurses++ form panel menu; do \
	    sudo ln -sf $${lib}w.pc "$(MNT)"/usr/lib/pkgconfig/$${lib}.pc; \
	done && \
	sudo sh -c 'echo "INPUT(-lncursesw)" > "$(MNT)"/usr/lib/libcursesw.so' && \
	sudo ln -sf libncurses.so "$(MNT)"/usr/lib/libcurses.so && \
	sudo ln -sf libncursesw.a "$(MNT)"/usr/lib/libcursesw.a && \
	sudo ln -sf libncurses.a "$(MNT)"/usr/lib/libcurses.a && \
	cd ../ncurses-build && \
	for lib in ncurses form panel menu; do \
	    sudo install -Dm755 lib/lib$${lib}.so.5.9 "$(MNT)"/usr/lib/lib$${lib}.so.5.9; \
	    sudo ln -sf lib$${lib}.so.5.9 "$(MNT)"/usr/lib/lib$${lib}.so.5; \
	done && \
	cd .. && \
	sudo install -dm755 "$(MNT)"/usr/share/licenses/ncurses && \
	sudo sh -c 'grep -B 100 \$$Id README > "$(MNT)"/usr/share/licenses/ncurses/license.txt' && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
netcfg:
	[ -f "netcfg-3.0.tar.xz" ] || \
	wget "ftp://ftp.archlinux.org/other/netcfg/netcfg-3.0.tar.xz"
	[ -d "netcfg-3.0" ] || \
	tar --xz --get < "netcfg-3.0.tar.xz"
	cd "netcfg-3.0" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)/usr/share/licenses/netcfg/LICENSE" && \
	sudo install -D -m644 contrib/bash-completion "$(MNT)/usr/share/bash-completion/completions/netcfg" && \
	sudo install -D -m644 contrib/zsh-completion "$(MNT)/usr/share/zsh/site-functions/_netcfg" && \
	sudo ln -sf netcfg.service "$(MNT)/usr/lib/systemd/system/net-profiles.service" && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
pcre:
	[ -f "pcre-8.32.tar.bz2" ] || \
	wget "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.32.tar.bz2"
	[ -d "pcre-8.32" ] || \
	tar --bzip2 --get < "pcre-8.32.tar.bz2"
	cd "pcre-8.32" && \
	./configure --prefix=/usr --enable-pcre16 --enable-pcre32 --enable-jit \
	    --enable-utf --enable-unicode-properties && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 LICENCE "$(MNT)"/usr/share/licenses/pcre/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (permissive free)
popt:
	[ -f "popt-1.16.tar.gz" ] || \
	wget "http://rpm5.org/files/popt/popt-1.16.tar.gz"
	[ -d "popt-1.16" ] || \
	tar --gzip --get < "popt-1.16.tar.gz"
	cd "popt-1.16" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/popt/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL, LGPL
sysfsutils:
	[ -f "sysfsutils-2.1.0.tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/linux-diag/sysfsutils-2.1.0.tar.gz"
	[ -d "sysfsutils-2.1.0" ] || \
	tar --gzip --get < "sysfsutils-2.1.0.tar.gz"
	cd "sysfsutils-2.1.0" && \
	./configure --prefix=/usr --mandir=/usr/share/man && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm "$(MNT)"/usr/lib/libsysfs.a && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# public domain, LGPL2+, GPL2+, GPL3+, custom (all premissive)
xz:
	[ -f "xz-5.0.4.tar.gz" ] || \
	wget "http://tukaani.org/xz/xz-5.0.4.tar.gz"
	[ -d "xz-5.0.4" ] || \
	tar --gzip --get < "xz-5.0.4.tar.gz"
	cd "xz-5.0.4" && \
	./configure --prefix=/usr --disable-rpath --enable-werror && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -d -m755 "$(MNT)"/usr/share/licenses/xz/ && \
	sudo ln -sf /usr/share/doc/xz/COPYING "$(MNT)"/usr/share/licenses/xz/COPYING && \
	sudo ln -sf /usr/share/licenses/common/LGPL2.1/license.txt "$(MNT)"/usr/share/doc/xz/COPYING.LGPLv2 && \
	sudo ln -sf /usr/share/licenses/common/GPL2/license.txt "$(MNT)"/usr/share/doc/xz/COPYING.GPLv2 && \
	sudo ln -sf /usr/share/licenses/common/GPL3/license.txt "$(MNT)"/usr/share/doc/xz/COPYING.GPLv3 && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (all premissive free)
zlib:
	[ -f "zlib-1.2.7.tar.gz" ] || \
	wget "http://zlib.net/current/zlib-1.2.7.tar.gz"
	[ -d "zlib-1.2.7" ] || \
	tar --gzip --get < "zlib-1.2.7.tar.gz"
	cd "zlib-1.2.7" && \
	./configure --prefix=/usr && \
	make && \
	grep -A 24 '^  Copyright' zlib.h > LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/zlib/LICENSE
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
ldns:
	[ -f "ldns-1.6.16.tar.gz" ] || \
	wget "http://www.nlnetlabs.nl/downloads/ldns/ldns-1.6.16.tar.gz"
	[ -d "ldns-1.6.16" ] || \
	tar --gzip --get < "ldns-1.6.16.tar.gz"
	cd "ldns-1.6.16" && \
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
	        --enable-static=no --disable-rpath --with-drill --with-examples && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)/usr/share/licenses/ldns/LICENSE"
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL2, LGPL2.1
keyutils:
	[ -f "keyutils-1.5.5.tar.gz" ] || \
	wget "http://people.redhat.com/~dhowells/keyutils/keyutils-1.5.5.tar.bz2"
	[ -d "keyutils-1.5.5" ] || \
	tar --bzip --get < "keyutils-1.5.5.tar.bz2"
	cd "keyutils-1.5.5" && \
	make CFLAGS="-O2 -pipe -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" \
	        LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" LIBDIR="/usr/lib" USRLIBDIR="/usr/lib" install && \
	sudo chmod a+w "$(MNT)"/etc/request-key.conf && \
	sudo echo "# NFS idmap resolver" >> "$(MNT)"/etc/request-key.conf && \
	sudo echo "create id_resolver * * /usr/sbin/nfsidmap %k %d" >> "$(MNT)"/etc/request-key.conf && \
	sudo chmod a-w "$(MNT)"/etc/request-key.conf && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
which:
	[ -f "which-2.20.tar.gz" ] || \
	wget "http://www.xs4all.nl/~carlo17/which/which-2.20.tar.gz"
	[ -d "which-2.20" ] || \
	tar --gzip --get < "which-2.20.tar.gz"
	cd "which-2.20" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
tar:
	[ -f "tar-1.26.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/gnu/tar/tar-1.26.tar.xz"
	[ -d "tar-1.26" ] || \
	tar --xz --get < "tar-1.26.tar.xz"
	cd "tar-1.26" && \
	sed -i -e '/gets is a/d' gnu/stdio.in.h && \
	./configure --prefix=/usr --libexecdir=/usr/lib/tar --bindir=/bin && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
sed:
	[ -f "sed-4.2.2.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/sed/sed-4.2.2.tar.gz"
	[ -d "sed-4.2.2" ] || \
	tar --gzip --get < "sed-4.2.2.tar.gz"
	cd "sed-4.2.2" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	sudo ln -s ../usr/bin/sed "$(MNT)"/bin && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
nano:
	[ -f "nano-2.2.6.tar.gz" ] || \
	wget "http://www.nano-editor.org/dist/v2.2/nano-2.2.6.tar.gz"
	[ -d "nano-2.2.6" ] || \
	tar --gzip --get < "nano-2.2.6.tar.gz"
	cd "nano-2.2.6" && \
	./configure --prefix=/usr --sysconfdir=/etc --enable-color \
	        --enable-nanorc --enable-multibuffer --disable-wrapping-as-root && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -DTm644 doc/nanorc.sample "$(MNT)"/etc/nanorc && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
coreutils:
	[ -f "$(COREUTILS).tar.xz" ] || \
	wget "http://ftp.gnu.org/gnu/coreutils/$(COREUTILS).tar.xz"
	[ -d "$(COREUTILS)" ] || \
	tar --xz --get < "$(COREUTILS).tar.xz"
	cd "$(COREUTILS)" && \
	./configure --prefix=/usr --libexecdir=/usr/libexec \
	        --enable-no-install-program=groups,hostname,kill,uptime && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	fhs=('cat' 'chgrp' 'chmod' 'chown' 'cp' 'date' 'dd' 'df' 'echo' 'false' 'ln' \
	     'ls' 'mkdir' 'mknod' 'mv' 'pwd' 'rm' 'rmdir' 'stty' 'sync' 'true' 'uname') && \
	for c in $${fhs[@]}; do  sudo ln -s ../usr/bin/$$c "$(MNT)"/bin/$$c;  done && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (permissive free)
db:
	[ -f "db-5.3.21.tar.gz" ] || \
	wget "http://download.oracle.com/berkeley-db/db-5.3.21.tar.gz"
	[ -d "db-5.3.21" ] || \
	tar --gzip --get < "db-5.3.21.tar.gz"
	cd "db-5.3.21/build_unix" && \
	../dist/configure --prefix=/usr --enable-compat185 --enable-shared \
	    --enable-static --enable-cxx --enable-dbm && \
	make LIBSO_LIBS=-lpthread && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm -r "$(MNT)"/usr/docs && \
	sudo install -Dm644 ../LICENSE "$(MNT)"/usr/share/licenses/db/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ../..

# GPL3
findutils:
	[ -f "findutils-4.4.2.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/findutils/findutils-4.4.2.tar.gz"
	[ -d "findutils-4.4.2" ] || \
	tar --gzip --get < "findutils-4.4.2.tar.gz"
	cd "findutils-4.4.2" && \
	sed -i '/^SUBDIRS/s/locate//' Makefile.in && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
gawk:
	[ -f "gawk-4.0.2.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/gawk/gawk-4.0.2.tar.gz"
	[ -d "gawk-4.0.2" ] || \
	tar --gzip --get < "gawk-4.0.2.tar.gz"
	cd "gawk-4.0.2" && \
	./configure --prefix=/usr --libexecdir=/usr/libexec && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/bin && \
	sudo ln -sf ../usr/bin/gawk "$(MNT)"/bin/gawk && \
	sudo ln -sf gawk "$(MNT)"/bin/awk && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
gettext:
	[ -f "gettext-0.18.2.1.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/gettext/gettext-0.18.2.1.tar.gz"
	[ -d "gettext-0.18.2.1" ] || \
	tar --gzip --get < "gettext-0.18.2.1.tar.gz"
	cd "gettext-0.18.2.1" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# LGPL3
gmp:
	[ -f "gmp-5.1.1.tar.xz" ] || \
	wget "ftp://ftp.gmplib.org/pub/gmp-5.1.1/gmp-5.1.1.tar.xz"
	[ -d "gmp-5.1.1" ] || \
	tar --xz --get < "gmp-5.1.1.tar.xz"
	cd "gmp-5.1.1" && \
	./configure --build=x86_64-unknown-linux-gnu --prefix=/usr --enable-cxx && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# MIT
libffi:
	[ -f "libffi-3.0.12.tar.gz" ] || \
	wget "ftp://sourceware.org/pub/libffi/libffi-3.0.12.tar.gz"
	[ -d "libffi-3.0.12" ] || \
	tar --gzip --get < "libffi-3.0.12.tar.gz"
	cd "libffi-3.0.12" && \
	./configure --prefix=/usr --disable-static && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/libffi/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# LGPL
libgcrypt:
	[ -f "libgcrypt-1.5.1.tar.gz" ] || \
	wget "ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.1.tar.bz2"
	[ -d "libgcrypt-1.5.1" ] || \
	tar --bzip2 --get < "libgcrypt-1.5.1.tar.bz2"
	cd "libgcrypt-1.5.1" && \
	./configure --prefix=/usr --disable-static --disable-padlock-support && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (permissive free)
bzip2:
	[ -f "bzip2-1.0.6.tar.gz" ] || \
	wget "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz"
	[ -d "bzip2-1.0.6" ] || \
	tar --gzip --get < "bzip2-1.0.6.tar.gz"
	cd "bzip2-1.0.6" && \
	sed -e 's/^CFLAGS=\(.*\)$$/CFLAGS=\1 \$$(BIGFILES)/' -i ./Makefile-libbz2_so && \
	patch -Np1 < ../patches/bzip2-1.0.4-bzip2recover.patch && \
	make -f Makefile-libbz2_so && \
	make bzip2 bzip2recover libbz2.a && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo install -dm755 "$(MNT)"/usr/{bin,lib,include,share/man/man1} && \
	sudo install -m755 bzip2-shared "$(MNT)"/usr/bin/bzip2 && \
	sudo install -m755 bzip2recover bzdiff bzgrep bzmore "$(MNT)"/usr/bin && \
	sudo ln -sf bzip2 "$(MNT)"/usr/bin/bunzip2 && \
	sudo ln -sf bzip2 "$(MNT)"/usr/bin/bzcat && \
	sudo install -m755 libbz2.so.1.0.6 "$(MNT)"/usr/lib && \
	sudo ln -sf libbz2.so.1.0.6 "$(MNT)"/usr/lib/libbz2.so && \
	sudo ln -sf libbz2.so.1.0.6 "$(MNT)"/usr/lib/libbz2.so.1 && \
	sudo ln -sf libbz2.so.1.0.6 "$(MNT)"/usr/lib/libbz2.so.1.0 && \
	sudo install -m644 libbz2.a "$(MNT)"/usr/lib/libbz2.a && \
	sudo install -m644 bzlib.h "$(MNT)"/usr/include/ && \
	sudo install -m644 bzip2.1 "$(MNT)"/usr/share/man/man1/ && \
	sudo ln -sf bzip2.1 "$(MNT)"/usr/share/man/man1/bunzip2.1 && \
	sudo ln -sf bzip2.1 "$(MNT)"/usr/share/man/man1/bzcat.1 && \
	sudo ln -sf bzip2.1 "$(MNT)"/usr/share/man/man1/bzip2recover.1 && \
	sudo install -Dm644 LICENSE "$(MNT)"/usr/share/licenses/bzip2/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
gdbm:
	[ -f "gdbm-1.10.tar.gz" ] || \
	wget "ftp://ftp.gnu.org/gnu/gdbm/gdbm-1.10.tar.gz"
	[ -d "gdbm-1.10" ] || \
	tar --gzip --get < "gdbm-1.10.tar.gz"
	cd "gdbm-1.10" && \
	patch -Np1 -i ../patches/gdbm-1.10-zeroheaders.patch && \
	./configure --prefix=/usr --mandir=/usr/share/man \
	        --infodir=/usr/share/info --enable-libgdbm-compat && \
	make prefix=/usr && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix="$(MNT)"/usr manprefix="$(MNT)"/usr/share/man \
	    man3dir="$(MNT)"/usr/share/man/man3 infodir="$(MNT)"/usr/share/info install && \
	sudo install -dm755 "$(MNT)"/usr/include/gdbm && \
	sudo ln -sf ../gdbm.h "$(MNT)"/usr/include/gdbm/gdbm.h && \
	sudo ln -sf ../ndbm.h "$(MNT)"/usr/include/gdbm/ndbm.h && \
	sudo ln -sf ../dbm.h  "$(MNT)"/usr/include/gdbm/dbm.h && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# LGPL
glib2:
	[ -f "glib-2.34.3.tar.xz" ] || \
	wget "http://ftp.gnome.org/pub/GNOME/sources/glib/2.34/glib-2.34.3.tar.xz"
	[ -d "glib-2.34.3" ] || \
	tar --xz --get < "glib-2.34.3.tar.xz"
	cd "glib-2.34.3" && \
	patch -Rp1 -i ../patches/revert-warn-glib-compile-schemas.patch && \
	export PYTHON=/usr/bin/python2 && \
	./configure --prefix=/usr --libdir=/usr/lib --sysconfdir=/etc --with-pcre=system --disable-fam && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make completiondir=/usr/share/bash-completion/completions DESTDIR="$(MNT)" install && \
	for s in "$(MNT)"/usr/share/bash-completion/completions/*; do  sudo chmod -x "$$s"; done && \
	sudo sed -i "s_#!/usr/bin/env python_#!/usr/bin/env python2_" "$(MNT)"/usr/bin/gdbus-codegen && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
grep:
	[ -f "grep-2.14.tar.xz" ] || \
	wget "ftp://ftp.gnu.org/gnu/grep/grep-2.14.tar.xz"
	[ -d "grep-2.14" ] || \
	tar --xz --get < "grep-2.14.tar.xz"
	cd "grep-2.14" && \
	./configure --prefix=/usr --without-included-regex && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
gzip:
	[ -f "gzip-1.5.tar.xz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/gzip/gzip-1.5.tar.xz"
	[ -d "gzip-1.5" ] || \
	tar --xz --get < "gzip-1.5.tar.xz"
	cd "gzip-1.5" && \
	./configure --prefix=/usr && \
	patch -p1 -i ../patches/gzip-1.5-yesno-declaration.patch && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL2
iproute2:
	[ -f "iproute2-3.8.0.tar.xz" ] || \
	wget "http://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-3.8.0.tar.xz"
	[ -d "iproute2-3.8.0" ] || \
	tar --xz --get < "iproute2-3.8.0.tar.xz"
	cd "iproute2-3.8.0" && \
	patch -Np1 -i ../patches/iproute2-fhs.patch && \
	./configure && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/sbin && \
	sudo mv "$(MNT)"/usr/sbin/ip "$(MNT)"/sbin/ip && \
	sudo ln -sf ../../sbin/ip "$(MNT)"/usr/sbin/ip && \
	sudo install -Dm644 include/libnetlink.h "$(MNT)"/usr/include/libnetlink.h && \
	sudo install -Dm644 lib/libnetlink.a "$(MNT)"/usr/lib/libnetlink.a && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL3
texinfo:
	[ -f "texinfo-5.1.tar.xz" ] || \
	wget "ftp://ftp.gnu.org/pub/gnu/texinfo/texinfo-5.1.tar.xz"
	[ -d "texinfo-5.1" ] || \
	tar --xz --get < "texinfo-5.1.tar.xz"
	cd "texinfo-5.1" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
# removed files are provided by util-linux, except for the corrected (made safer) link
sysvinit:
	[ -f "$(SYSVINIT).tar.bz2" ] || \
	wget "http://download.savannah.gnu.org/releases/sysvinit/$(SYSVINIT).tar.bz2"
	[ -d "$(SYSVINIT)" ] || \
	tar --bzip2 --get < "$(SYSVINIT).tar.bz2"
	pushd "$(SYSVINIT)" && \
	([ ! "$(SYSVINIT_SIMPLIFY_WRITELOG)" = "y" ] || \
	        patch -p1 -d "src" -i ../../patches/0001-simplify-writelog.patch) && \
	([ "$(SYSVINIT_ANSI)" = "y" ] || \
	        patch -p1 -d "src" -i ../../patches/0002-remove-ansi-escape-codes-from-log-file.patch) && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo mkdir -p "$(MNT)/__pony_temp__" && \
	sudo make ROOT="$(MNT)/__pony_temp__" install && \
	cd "$(MNT)/__pony_temp__" && \
	sudo rm bin/pidof && \
	sudo ln -sf ../sbin/killall5 bin/pidof && \
	sudo rm bin/mountpoint \
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
	sudo rm -r __pony_temp__ && \
	popd && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
openssl:
	[ -f "openssl-1.0.1e.tar.gz" ] || \
	wget "https://www.openssl.org/source/openssl-1.0.1e.tar.gz"
	[ -d "openssl-1.0.1e" ] || \
	tar --gzip --get < "openssl-1.0.1e.tar.gz"
	cd "openssl-1.0.1e" && \
	if [ "$(ARCH)" = 'x86_64' ]; then \
	        export openssltarget='linux-x86_64'; \
	        export optflags='enable-ec_nistp_64_gcc_128'; \
	elif [ "$(ARCH)" = 'i686' ]; then \
	        export openssltarget='linux-elf'; \
	        export optflags=''; \
	fi && \
	patch -p0 -i ../patches/no-rpath.patch && \
	patch -p0 -i ../patches/ca-dir.patch && \
	./Configure --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib \
	        $${optflags} "$${openssltarget}" -Wa,--noexecstack \
	        "-fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" \
	        "-Wl,-O1,--sort-common,--as-needed,-z,relro" && \
	make depend && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make INSTALL_PREFIX="$(MNT)" MANDIR=/usr/share/man MANSUFFIX=ssl install && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/openssl/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
libtirpc:
	[ -f "libtirpc-0.2.2.tar.bz2" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/libtirpc/libtirpc-0.2.2.tar.bz2"
	[ -d "libtirpc-0.2.2" ] || \
	tar --bzip2 --get < "libtirpc-0.2.2.tar.bz2"
	cd "libtirpc-0.2.2" && \
	patch -Np1 -i ../patches/libtirpc-0.2.1-fortify.patch && \
	patch -Np1 -i ../patches/libtirpc-0.2.3rc1.patch && \
	patch -Np1 -i ../patches/libtirpc-fix-segfault-0.2.2.patch && \
	sh autogen.sh && \
	autoreconf -fisv && \
	./configure --prefix=/usr --enable-ges && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 doc/etc_netconfig "$(MNT)"/etc/netconfig && \
	sudo install -D -m644 COPYING "$(MNT)"/usr/share/licenses/libtirpc/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
libpcap:
	[ -f "libpcap-1.3.0.tar.gz" ] || \
	wget "http://www.tcpdump.org/release/libpcap-1.3.0.tar.gz"
	[ -d "libpcap-1.3.0" ] || \
	tar --gzip --get < "libpcap-1.3.0.tar.gz"
	cd "libpcap-1.3.0" && \
	patch -Np1 -i ../patches/libpcap-libnl32.patch && \
	autoreconf -f -i && \
	./configure --prefix=/usr --enable-ipv6 --with-libnl && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo mkdir -p "$(MNT)"/usr/bin && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm -rf "$(MNT)"/usr/lib/libpcap.a && \
	sudo mkdir -p "$(MNT)"/usr/include/net && \
	sudo ln -sf ../pcap-bpf.h "$(MNT)"/usr/include/net/bpf.h && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/libpcap/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# BSD
libgssglue:
	[ -f "libgssglue-0.4.tar.gz" ] || \
	wget "http://www.citi.umich.edu/projects/nfsv4/linux/libgssglue/libgssglue-0.4.tar.gz"
	[ -d "libgssglue-0.4" ] || \
	tar --gzip --get < "libgssglue-0.4.tar.gz"
	cd "libgssglue-0.4" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)/" install && \
	sudo install -Dm644 ../confs/gssapi_mech.conf "$(MNT)"/etc/gssapi_mech.conf && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/libgssglue/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
readline:
	[ -f "readline-6.2.tar.gz" ] || \
	wget "http://ftp.gnu.org/gnu/readline/readline-6.2.tar.gz"
	[ -d "readline-6.2" ] || \
	tar --gzip --get < "readline-6.2.tar.gz"
	[ -f "readline62-001" ] || wget "http://ftp.gnu.org/gnu/readline/readline-6.2-patches/readline62-001"
	[ -f "readline62-002" ] || wget "http://ftp.gnu.org/gnu/readline/readline-6.2-patches/readline62-002"
	[ -f "readline62-003" ] || wget "http://ftp.gnu.org/gnu/readline/readline-6.2-patches/readline62-003"
	[ -f "readline62-004" ] || wget "http://ftp.gnu.org/gnu/readline/readline-6.2-patches/readline62-004"
	cd "readline-6.2" && \
	patch -Np0 -i ../readline62-001 && \
	patch -Np0 -i ../readline62-002 && \
	patch -Np0 -i ../readline62-003 && \
	patch -Np0 -i ../readline62-004 && \
	sed -i 's_-Wl,-rpath,$$(libdir) __g' support/shobj-conf && \
	./configure --prefix=/usr && \
	make CFLAGS=-fPIC SHLIB_LIBS=-lncurses && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)/" install && \
	sudo install -Dm644 ../confs/inputrc "$(MNT)"/etc/inputrc && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL2
kmod:
	[ -f "kmod-12.tar.gz" ] || \
	wget "ftp://ftp.kernel.org/pub/linux/utils/kernel/kmod/kmod-12.tar.xz"
	[ -d "kmod-12" ] || \
	tar --xz --get < "kmod-12.tar.xz"
	cd "kmod-12" && \
	./configure --sysconfdir=/etc --enable-gtk-doc --with-zlib && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)/" install && \
	sudo install -dm755 "$(MNT)"/{etc,usr/lib}/{depmod,modprobe}.d "$(MNT)/sbin" && \
	sudo ln -sf ../usr/bin/kmod "$(MNT)/sbin/modprobe" && \
	sudo ln -sf ../usr/bin/kmod "$(MNT)/sbin/depmod" && \
	for tool in {ins,ls,rm}mod modinfo; do \
	    sudo ln -sf kmod "$(MNT)/usr/bin/$$tool"; \
	done && \
	sudo install -Dm644 "../confs/depmod-search.conf" "$(MNT)/usr/lib/depmod.d/search.conf" && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL, LGPL, MIT
e2fsprogs:
	[ -f "e2fsprogs-1.42.7.tar.gz" ] || \
	wget "http://downloads.sourceforge.net/sourceforge/e2fsprogs/e2fsprogs-1.42.7.tar.gz"
	[ -d "e2fsprogs-1.42.7" ] || \
	tar --gzip --get < "e2fsprogs-1.42.7.tar.gz"
	cd "e2fsprogs-1.42.7" && \
	sed -i '/init\.d/s|^|#|' misc/Makefile.in && \
	./configure --prefix=/usr --with-root-prefix="" --libdir=/usr/lib \
	        --enable-elf-shlibs --disable-fsck --disable-uuidd \
	        --disable-libuuid --disable-libblkid && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install install-libs && \
	sudo sed -i -e 's/^AWK=.*/AWK=awk/' "$(MNT)/usr/bin/compile_et" && \
	sudo sed -i -e 's#^SS_DIR=.*#SS_DIR="/usr/share/ss"#' "$(MNT)/usr/bin/mk_cmds" && \
	sudo sed -i -e 's#^ET_DIR=.*#ET_DIR="/usr/share/et"#' "$(MNT)/usr/bin/compile_et" && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# GPL
bash:
	[ -f "bash-4.2.tar.gz" ] || \
	wget "http://ftp.gnu.org/gnu/bash/bash-4.2.tar.gz"
	[ -d "bash-4.2" ] || \
	tar --gzip --get < "bash-4.2.tar.gz"
	for (( p=1; p<=45; p++ )); do \
	    [ -f "bash42-$$(printf "%03d" $$p)" ] || \
                wget "http://ftp.gnu.org/gnu/bash/bash-4.2-patches/bash42-$$(printf "%03d" $$p)"; \
	done && \
	cd "bash-4.2" && \
	for (( p=1; p<=45; p++ )); do \
	    patch -Np0 -i "../bash42-$$(printf "%03d" $$p)"; \
	done && \
	bashconfig=(-DDEFAULT_PATH_VALUE=\'\"/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\"\' \
	        -DSTANDARD_UTILS_PATH=\'\"/usr/bin:/bin:/usr/sbin:/sbin\"\' \
	        -DSYS_BASHRC=\'\"/etc/bash.bashrc\"\' \
	        -DSYS_BASH_LOGOUT=\'\"/etc/bash.bash_logout\"\') && \
	./configure --prefix=/usr --with-curses --enable-readline \
	        --without-bash-malloc --with-installed-readline && \
	make CFLAGS="${bashconfig[@]}" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -dm755  "$(MNT)"/bin && \
	sudo ln -sf ../usr/bin/bash "$(MNT)"/bin/bash && \
	sudo ln -sf ../usr/bin/bash "$(MNT)"/bin/sh && \
	sudo mkdir -p "$(MNT)"/etc/skel/ && \
	sudo install -m644 ../confs/system.bashrc "$(MNT)"/etc/bash.bashrc && \
	sudo install -m644 ../confs/system.bash_logout "$(MNT)"/etc/bash.bash_logout && \
	sudo install -m644 ../confs/user.bashrc "$(MNT)"/etc/skel/.bashrc && \
	sudo install -m644 ../confs/user.bash_profile "$(MNT)"/etc/skel/.bash_profile && \
	sudo install -m644 ../confs/user.bash_logout "$(MNT)"/etc/skel/.bash_logout && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

# custom (permissive free)
# splitpackages: libsasl, cyrus-sasl, cyrus-sasl-gssapi, cyrus-sasl-ldap
libsasl:
	[ -f "cyrus-sasl-2.1.23.tar.gz" ] || \
	wget "ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/cyrus-sasl-2.1.23.tar.gz"
	[ -d "cyrus-sasl-2.1.23" ] || \
	tar --gzip --get < "cyrus-sasl-2.1.23.tar.gz"
	cd "cyrus-sasl-2.1.23" && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.19-checkpw.c.patch && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.22-crypt.patch && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.22-qa.patch && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.22-automake-1.10.patch && \
	patch -Np0 -i ../patches/cyrus-sasl-2.1.23-authd-fix.patch && \
	patch -Np1 -i ../patches/0003_saslauthd_mdoc.patch && \
	patch -Np1 -i ../patches/0010_maintainer_mode.patch && \
	patch -Np1 -i ../patches/0011_saslauthd_ac_prog_libtool.patch && \
	patch -Np1 -i ../patches/0012_xopen_crypt_prototype.patch && \
	patch -Np1 -i ../patches/0016_pid_file_lock_creation_mask.patch && \
	patch -Np1 -i ../patches/0018_auth_rimap_quotes.patch && \
	patch -Np1 -i ../patches/0019_ldap_deprecated.patch && \
	patch -Np1 -i ../patches/0022_gcc4.4_preprocessor_syntax.patch && \
	patch -Np1 -i ../patches/0025_ld_as_needed.patch && \
	patch -Np1 -i ../patches/0026_drop_krb5support_dependency.patch && \
	patch -Np1 -i ../patches/0027_db5_support.patch && \
	patch -Np1 -i ../patches/0030-dont_use_la_files_for_opening_plugins.patch && \
	rm -f config/config.guess config/config.sub && \
	rm -f config/ltconfig config/ltmain.sh config/libtool.m4 && \
	rm -fr autom4te.cache && \
	libtoolize -c && \
	aclocal -I config -I cmulocal && \
	automake -a -c && \
	autoheader && \
	autoconf && \
	cd saslauthd && \
	rm -f config/config.guess config/config.sub  && \
	rm -f config/ltconfig config/ltmain.sh config/libtool.m4 && \
	rm -fr autom4te.cache && \
	libtoolize -c && \
	aclocal -I config -I ../cmulocal -I ../config && \
	automake -a -c && \
	autoheader && \
	autoconf && \
	cd .. && \
	./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --disable-static \
	        --enable-shared --enable-alwaystrue --enable-checkapop --enable-cram --enable-digest \
	        --disable-otp --disable-srp --disable-srp-setpass --disable-krb4 --enable-gssapi \
	        --enable-auth-sasldb --enable-plain --enable-anon --enable-login --enable-ntlm \
	        --disable-passdss --enable-sql --enable-ldapdb --disable-macos-framework --with-pam \
	        --with-saslauthd=/var/run/saslauthd --with-ldap \
	        --with-configdir=/etc/sasl2:/etc/sasl:/usr/lib/sasl2 \
	        --sysconfdir=/etc --with-devrandom=/dev/urandom && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	for dir in include lib sasldb plugins utils; do \
	    cd $$dir && if sudo make DESTDIR="$(MNT)" install; then cd ..; else exit 1; fi; \
	done && \
	sudo rm -f "$(MNT)"/usr/lib/sasl2/libsql.so* && \
	sudo rm -f "$(MNT)"/usr/lib/sasl2/libgssapiv2.so* && \
	sudo rm -f "$(MNT)"/usr/lib/sasl2/libldapdb.so* && \
	sudo install -m755 -d "$(MNT)"/usr/share/licenses/libsasl && \
	sudo install -m644 COPYING "$(MNT)"/usr/share/licenses/libsasl/ && \
	cd saslauthd && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -m755 -d "$(MNT)"/etc/rc.d && \
	sudo install -m755 -d "$(MNT)"/etc/conf.d && \
	sudo install -m755 ../../confs/saslauthd "$(MNT)"/etc/rc.d/ && \
	sudo install -m644 ../../confs/saslauthd.conf.d "$(MNT)"/etc/conf.d/saslauthd && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/cyrus-sasl && \
	sudo ln -sf ../libsasl/COPYING "$(MNT)"/usr/share/licenses/cyrus-sasl/COPYING && \
	cd ../plugins && \
	sudo cp -a .libs/libgssapiv2.so* "$(MNT)"/usr/lib/sasl2/ && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/cyrus-sasl-gssapi && \
	sudo ln -sf ../libsasl/COPYING "$(MNT)"/usr/share/licenses/cyrus-sasl-gssapi/COPYING && \
	sudo mkdir -p "$(MNT)"/usr/lib/sasl2 && \
	sudo cp -a .libs/libldapdb.so* "$(MNT)"/usr/lib/sasl2/ && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/cyrus-sasl-ldap && \
	sudo ln -sf ../COPYING "$(MNT)"/usr/share/licenses/cyrus-sasl-ldap/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ../..


