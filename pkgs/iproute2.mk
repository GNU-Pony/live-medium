# GPL2
IPROUTE2 = iproute2-$(IPROUTE2_VERION)
CLEAN_DIR += "$(IPROUTE2)"
packages: iproute2
iproute2:
	[ -f "$(IPROUTE2).tar.xz" ] || \
	wget "http://www.kernel.org/pub/linux/utils/net/iproute2/$(IPROUTE2).tar.xz"
	[ -d "$(IPROUTE2)" ] || \
	tar --xz --get < "$(IPROUTE2).tar.xz"
	cd "$(IPROUTE2)" && \
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

