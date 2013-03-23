# BSD
LIBPCAP = libpcap-$(LIBPCAP_VERSION)
CLEAN_DIR += "$(LIBPCAP)"
packages: libpcap
libpcap:
	[ -f "$(LIBPCAP).tar.gz" ] || \
	wget "http://www.tcpdump.org/release/$(LIBPCAP).tar.gz"
	[ -d "$(LIBPCAP)" ] || \
	tar --gzip --get < "$(LIBPCAP).tar.gz"
	cd "$(LIBPCAP)" && \
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

