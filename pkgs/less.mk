# GPL3
LESS = less-$(LESS_VERSION)
CLEAN_DIR += "$(LESS)"
packages: less
less:
	[ -f "$(LESS).tar.gz" ] || \
	wget "http://www.greenwoodsoftware.com/less/$(LESS).tar.gz"
	[ -d "$(LESS)" ] || \
	tar --gzip --get < "$(LESS).tar.gz"
	cd "$(LESS)" && \
	./configure --prefix=/usr --sysconfdir=/etc --with-regex=pcre && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make prefix="$(MNT)"/usr install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

