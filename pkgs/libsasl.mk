# custom (permissive free)
# split packages: libsasl, cyrus-sasl, cyrus-sasl-gssapi, cyrus-sasl-ldap
LIBSASL = cyrus-sasl-$(LIBSASL_VERSION)
CLEAN_DIR += "$(LIBSASL)"
packages: libsasl
libsasl:
	[ -f "$(LIBSASL).tar.gz" ] || \
	wget "ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/$(LIBSASL).tar.gz"
	[ -d "$(LIBSASL)" ] || \
	tar --gzip --get < "$(LIBSASL).tar.gz"
	cd "$(LIBSASL)" && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.19-checkpw.c.patch && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.22-crypt.patch && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.22-qa.patch && \
	patch -Np1 -i ../patches/cyrus-sasl-2.1.22-automake-1.10.patch && \
	patch -Np0 -i ../patches/cyrus-sasl-2.1.23-authd-fix.patch && \
	patch -Np1 -i ../patches/0003_saslauthd_mdoc.patch && \
	patch -Np1 -i ../patches/0010_maintainer_mode.patch && \
	patch -Np1 -i ../patches/0011_saslauthd_ac_prog_libtool.patch && \
	patch -Np1 -i ../patches/0012_xopen_crypt_prototype.patch && \
	patch -Np1 -i ../patches/0016_pid_file_lock_creation_mask.patch && \
	patch -Np1 -i ../patches/0018_auth_rimap_quotes.patch && \
	patch -Np1 -i ../patches/0019_ldap_deprecated.patch && \
	patch -Np1 -i ../patches/0022_gcc4.4_preprocessor_syntax.patch && \
	patch -Np1 -i ../patches/0025_ld_as_needed.patch && \
	patch -Np1 -i ../patches/0026_drop_krb5support_dependency.patch && \
	patch -Np1 -i ../patches/0027_db5_support.patch && \
	patch -Np1 -i ../patches/0030-dont_use_la_files_for_opening_plugins.patch && \
	rm -f config/config.guess config/config.sub && \
	rm -f config/ltconfig config/ltmain.sh config/libtool.m4 && \
	rm -fr autom4te.cache && \
	libtoolize -c && \
	aclocal -I config -I cmulocal && \
	automake -a -c && \
	autoheader && \
	autoconf && \
	cd saslauthd && \
	rm -f config/config.guess config/config.sub  && \
	rm -f config/ltconfig config/ltmain.sh config/libtool.m4 && \
	rm -fr autom4te.cache && \
	libtoolize -c && \
	aclocal -I config -I ../cmulocal -I ../config && \
	automake -a -c && \
	autoheader && \
	autoconf && \
	cd .. && \
	./configure --prefix=/usr --mandir=/usr/share/man --infodir=/usr/share/info --disable-static \
	        --enable-shared --enable-alwaystrue --enable-checkapop --enable-cram --enable-digest \
	        --disable-otp --disable-srp --disable-srp-setpass --disable-krb4 --enable-gssapi \
	        --enable-auth-sasldb --enable-plain --enable-anon --enable-login --enable-ntlm \
	        --disable-passdss --enable-sql --enable-ldapdb --disable-macos-framework --with-pam \
	        --with-saslauthd=/var/run/saslauthd --with-ldap \
	        --with-configdir=/etc/sasl2:/etc/sasl:/usr/lib/sasl2 \
	        --sysconfdir=/etc --with-devrandom=/dev/urandom && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	for dir in include lib sasldb plugins utils; do \
	    cd $$dir && if sudo make DESTDIR="$(MNT)" install; then cd ..; else exit 1; fi; \
	done && \
	sudo rm -f "$(MNT)"/usr/lib/sasl2/libsql.so* && \
	sudo rm -f "$(MNT)"/usr/lib/sasl2/libgssapiv2.so* && \
	sudo rm -f "$(MNT)"/usr/lib/sasl2/libldapdb.so* && \
	sudo install -m755 -d "$(MNT)"/usr/share/licenses/libsasl && \
	sudo install -m644 COPYING "$(MNT)"/usr/share/licenses/libsasl/ && \
	cd saslauthd && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -m755 -d "$(MNT)"/etc/rc.d && \
	sudo install -m755 -d "$(MNT)"/etc/conf.d && \
	sudo install -m755 ../../confs/saslauthd "$(MNT)"/etc/rc.d/ && \
	sudo install -m644 ../../confs/saslauthd.conf.d "$(MNT)"/etc/conf.d/saslauthd && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/cyrus-sasl && \
	sudo ln -sf ../libsasl/COPYING "$(MNT)"/usr/share/licenses/cyrus-sasl/COPYING && \
	cd ../plugins && \
	sudo cp -a .libs/libgssapiv2.so* "$(MNT)"/usr/lib/sasl2/ && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/cyrus-sasl-gssapi && \
	sudo ln -sf ../libsasl/COPYING "$(MNT)"/usr/share/licenses/cyrus-sasl-gssapi/COPYING && \
	sudo mkdir -p "$(MNT)"/usr/lib/sasl2 && \
	sudo cp -a .libs/libldapdb.so* "$(MNT)"/usr/lib/sasl2/ && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/cyrus-sasl-ldap && \
	sudo ln -sf ../COPYING "$(MNT)"/usr/share/licenses/cyrus-sasl-ldap/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ../..
	echo "[$@]" >> built

