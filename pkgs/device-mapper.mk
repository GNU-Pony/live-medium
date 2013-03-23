# GPL2, LGPL2.1
# make dependencies: systemd
DEVICE_MAPPER = LVM2-$(DEVICE_MAPPER_VERSION)
DEVICE_MAPPER_ = LVM2.$(DEVICE_MAPPER_VERSION)
CLEAN_DIR += "$(DEVICE_MAPPER)"
packages: device-mapper
device-mapper:
	[ -f "$(DEVICE_MAPPER).tar.gz" ] || \
	wget "ftp://sources.redhat.com/pub/lvm2/$(DEVICE_MAPPER_).tgz" -O "$(DEVICE_MAPPER).tar.gz"
	[ -d "$(DEVICE_MAPPER)" ] || \
	(tar --gzip --get < "$(DEVICE_MAPPER).tar.gz" && mv $(DEVICE_MAPPER_) $(DEVICE_MAPPER))
	cd "$(DEVICE_MAPPER)" && \
	unset LDFLAGS && \
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --with-udev-prefix=/usr \
	        --with-systemdsystemunitdir=/usr/lib/systemd/system --with-default-pid-dir=/run \
	        --with-default-dm-run-dir=/run --with-default-run-dir=/run/lvm \
	        --enable-pkgconfig --enable-readline --enable-dmeventd --enable-cmdlib --enable-applib \
	        --enable-udev_sync --enable-udev_rules --with-default-locking-dir=/run/lock/lvm \
	        --enable-lvmetad && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install_device-mapper && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

