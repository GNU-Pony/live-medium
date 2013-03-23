# custom (permissive free)
LIBLDAP_MAJOR = $(shell echo $(KRB5_VERSION) | cut -d . -f 1)
LIBLDAP = openldap-$(LIBLDAP_VERSION)
CLEAN_DIR += "$(LIBLDAP)"
packages: libldap
libldap:
	[ -f "$(LIBLDAP).tgz" ] || \
	wget "ftp://ftp.openldap.org/pub/OpenLDAP/openldap-release/$(LIBLDAP).tgz"
	[ -d "$(LIBLDAP)" ] || \
	tar --gzip --get < "$(LIBLDAP).tgz"
	cd "$(LIBLDAP)" && \
	patch -Np1 -i ../patches/ntlm.patch && \
	sed -i 's#-m 644 $$(LIBRARY)#-m 755 $$(LIBRARY)#' \
	        libraries/{liblber,libldap,libldap_r}/Makefile.in && \
	sed -i 's|#define LDAPI_SOCK LDAP_RUNDIR LDAP_DIRSEP "run" LDAP_DIRSEP "ldapi"|#define LDAPI_SOCK LDAP_DIRSEP "run" LDAP_DIRSEP "openldap" LDAP_DIRSEP "ldapi"|' \
	        include/ldap_defaults.h && \
	sed -i 's|%LOCALSTATEDIR%/run|/run/openldap|' servers/slapd/slapd.conf && \
	sed -i 's|-$$(MKDIR) $$(DESTDIR)$$(localstatedir)/run|-$$(MKDIR) $$(DESTDIR)/run/openldap|' \
	        servers/slapd/Makefile.in && \
	./configure --prefix=/usr --mandir=/usr/share/man --libexecdir=/usr/lib --sysconfdir=/etc \
	        --localstatedir=/var/lib/openldap --enable-ipv6 --enable-syslog --enable-local \
	        --enable-bdb --enable-hdb --enable-crypt --enable-dynamic --with-threads \
	        --disable-wrappers --without-fetch --enable-spasswd --with-cyrus-sasl \
	        --enable-overlays=mod --enable-modules=yes && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	for dir in include libraries doc/man/man3 ; do \
	    cd $${dir} && sudo make DESTDIR="$(MNT)" install && cd ..; \
	done && cd ../.. && \
	sudo install -Dm644 doc/man/man5/ldap.conf.5.tmp "$(MNT)"/usr/share/man/man5/ldap.conf.5 && \
	sudo rm "$(MNT)"/etc/openldap/*.default && \
	sudo ln -sf liblber.so "$(MNT)"/usr/lib/liblber.so.$(LIBLDAP_MAJOR) && \
	sudo ln -sf libldap.so "$(MNT)"/usr/lib/libldap.so.$(LIBLDAP_MAJOR) && \
	sudo install -Dm644 LICENSE "$(MNT)"/usr/share/licenses/libldap/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

