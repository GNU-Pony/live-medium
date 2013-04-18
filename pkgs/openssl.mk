# BSD
OPENSSL = openssl-$(OPENSSL_VERSION)
CLEAN_DIR += "$(OPENSSL)"
packages: openssl
openssl:
	[ -f "$(OPENSSL).tar.gz" ] || \
	wget "https://www.openssl.org/source/$(OPENSSL).tar.gz"
	[ -d "$(OPENSSL)" ] || \
	tar --gzip --get < "$(OPENSSL).tar.gz"
	cd "$(OPENSSL)" && \
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
	echo "[$@]" >> built

