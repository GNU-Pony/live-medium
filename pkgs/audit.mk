# GPL
# makedependency: libldap, swig, linux-headers, python2
AUDIT = audit-$(AUDIT_VERSION)
CLEAN_DIR += "$(AUDIT)"
packages: audit
audit:
	[ -f "$(AUDIT).tar.gz" ] || \
	wget "http://people.redhat.com/sgrubb/audit/$(AUDIT).tar.gz"
	[ -d "$(AUDIT)" ] || \
	tar --gzip --get < "$(AUDIT).tar.gz"
	cd "$(AUDIT)" && \
	patch -p0 -i "../patches/audit-python2.patch" && \
	./configure --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/libexec/audit \
	    --with-python=yes --enable-gssapi-krb5=yes --with-libcap-ng=yes && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built
