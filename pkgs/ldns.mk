# BSD
LDNS = ldns-$(LDNS_VERSION)
CLEAN_DIR += "$(LDNS)"
packages: ldns
ldns:
	[ -f "$(LDNS).tar.gz" ] || \
	wget "http://www.nlnetlabs.nl/downloads/ldns/$(LDNS).tar.gz"
	[ -d "$(LDNS)" ] || \
	tar --gzip --get < "$(LDNS).tar.gz"
	cd "$(LDNS)" && \
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var \
	        --enable-static=no --disable-rpath --with-drill --with-examples && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)/usr/share/licenses/ldns/LICENSE"
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

