# custom (permissive free)
KRB5_MAJOR = $(shell echo $(KRB5_VERSION) | cut -d . -f 1,2)
KRB5 = krb5-$(KRB5_VERSION)
CLEAN_DIR += "$(KRB5)"
packages: krb5
krb5:
	[ -f "$(KRB5)-signed.tar" ] || \
	wget "http://web.mit.edu/kerberos/dist/krb5/$(KRB5_MAJOR)/$(KRB5)-signed.tar"
	[ -f "$(KRB5).tar.gz" ] || \
	tar --get < "$(KRB5)-signed.tar"
	[ -d "$(KRB5)" ] || \
	tar --gzip --get < "$(KRB5).tar.gz"
	cd "$(KRB5)/src" && \
	sed -i s_\''"$$LDFLAG S"'\'__g krb5-config.in && \
	sed -i "/KRB5ROOT=/s/\/local//" util/ac_check_krb5.m4 && \
	flags="-O2 -pipe -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" && \
	export CFLAGS="$$flags -fPIC -fno-strict-aliasing -fstack-protector-all" && \
	export CPPFLAGS="$$flags -I/usr/include/et" && \
	./configure --prefix=/usr --sysconfdir=/etc --mandir=/usr/share/man \
	        --localstatedir=/var/lib --enable-shared --with-system-et \
	        --with-system-ss --disable-rpath --without-tcl --enable-dns-for-realm \
	        --with-ldap --without-system-verto && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" EXAMPLEDIR=/usr/share/doc/krb5/examples install && \
	sudo install -m 644 plugins/kdb/ldap/libkdb_ldap/kerberos.{ldif,schema} \
	        "$(MNT)"/usr/share/doc/krb5/examples && \
	sudo install -dm 755 "$(MNT)"/var/lib/krb5kdc && \
	sudo install -pm 644 config-files/kdc.conf "$(MNT)"/var/lib/krb5kdc/kdc.conf && \
	sudo install -dm 755 "$(MNT)"/etc && \
	sudo install -pm 644 config-files/krb5.conf "$(MNT)"/etc/krb5.conf && \
	sudo install -dm 755 "$(MNT)"/etc/rc.d && \
	sudo install -m 755 ../../confs/krb5-{kdc,kadmind,kpropd} "$(MNT)"/etc/rc.d && \
	sudo install -dm 755 "$(MNT)"/usr/share/aclocal && \
	sudo install -m 644 util/ac_check_krb5.m4 "$(MNT)"/usr/share/aclocal && \
	sudo install -Dm644 ../NOTICE "$(MNT)"/usr/share/licenses/krb5/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ../..
	echo "[$@]" >> built

