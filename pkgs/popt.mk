# custom (permissive free)
POPT = popt-$(POPT_VERSION)
CLEAN_DIR += "$(POPT)"
packages: popt
popt:
	[ -f "$(POPT).tar.gz" ] || \
	wget "http://rpm5.org/files/popt/$(POPT).tar.gz"
	[ -d "$(POPT)" ] || \
	tar --gzip --get < "$(POPT).tar.gz"
	cd "$(POPT)" && \
	./configure --prefix=/usr && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/popt/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

