# custom (permissive free)
DB = db-$(DB_VERSION)
CLEAN_DIR += "$(DB)"
packages: db
db:
	[ -f "$(DB).tar.gz" ] || \
	wget "http://download.oracle.com/berkeley-db/$(DB).tar.gz"
	[ -d "$(DB)" ] || \
	tar --gzip --get < "$(DB).tar.gz"
	cd "$(DB)/build_unix" && \
	../dist/configure --prefix=/usr --enable-compat185 --enable-shared \
	    --enable-static --enable-cxx --enable-dbm && \
	make LIBSO_LIBS=-lpthread && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm -r "$(MNT)"/usr/docs && \
	sudo install -Dm644 ../LICENSE "$(MNT)"/usr/share/licenses/db/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ../..
	echo "[$@]" >> built

