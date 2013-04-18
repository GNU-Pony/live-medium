# MIT
CURL = curl-$(CURL_VERSION)
CLEAN_DIR += "$(CURL)"
packages: curl
curl:
	[ -f "$(CURL).tar.gz" ] || \
	wget "http://curl.haxx.se/download/$(CURL).tar.gz"
	[ -d "$(CURL)" ] || \
	tar --gzip --get < "$(CURL).tar.gz"
	cd "$(CURL)" && \
	curlbuild=curlbuild-"$$(( 8 * $$(cpp <<<'__SIZEOF_POINTER__' | sed '/^#/d') ))".h && \
	patch -Np1 < ../patches/0001-Fix-NULL-pointer-reference-when-closing-an-unused-mu.patch && \
	./configure --prefix=/usr --mandir=/usr/share/man --disable-dependency-tracking \
	        --disable-ldap --disable-ldaps --enable-ipv6 --enable-manual --enable-versioned-symbols \
	        --enable-threaded-resolver --without-libidn --with-random=/dev/urandom \
	        --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/curl/COPYING && \
	sudo install -Dm644 docs/libcurl/libcurl.m4 "$(MNT)"/usr/share/aclocal/libcurl.m4 && \
	sudo mv "$(MNT)"/usr/include/curl/curlbuild.h "$(MNT)"/usr/include/curl/$$curlbuild && \
	sudo install -m644 ../patches/curlbuild.h "$(MNT)"/usr/include/curl/curlbuild.h && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

