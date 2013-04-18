# GPL, PerlArtistic
PERL_MAJOR = $(shell echo $(PERL_VERSION) | cut -d . -f 1)
PERL = perl-$(PERL_VERSION)
CLEAN_DIR += "$(PERL)" "perl-build"
packages: perl
perl:
	[ -f "$(PERL).tar.bz2" ] || \
	wget "http://www.cpan.org/src/$(PERL_MAJOR).0/$(PERL).tar.bz2"
	[ -d "$(PERL)" ] || \
	tar --bzip2 --get < "$(PERL).tar.bz2"
	cd "$(PERL)" && \
	patch -i ../patches/cgi-cr-escaping.diff -p1 && \
	if [ "$(ARCH)" = "x86_64" ]; then \
	    ARCHOPTS="-Dcccdlflags='-fPIC'"; \
	else \
	    ARCHOPTS=""; \
	fi && \
	CFLAGS="-O2 -pipe -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" && \
	LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro" && \
	./Configure -des -Dusethreads -Duseshrplib -Doptimize="$${CFLAGS}" \
	        -Dprefix=/usr -Dvendorprefix=/usr \
	        -Dprivlib=/usr/share/perl$(PERL_MAJOR)/core_perl \
	        -Darchlib=/usr/lib/perl$(PERL_MAJOR)/core_perl \
	        -Dsitelib=/usr/share/perl$(PERL_MAJOR)/site_perl \
	        -Dsitearch=/usr/lib/perl$(PERL_MAJOR)/site_perl \
	        -Dvendorlib=/usr/share/perl$(PERL_MAJOR)/vendor_perl \
	        -Dvendorarch=/usr/lib/perl$(PERL_MAJOR)/vendor_perl \
	        -Dscriptdir=/usr/bin/core_perl \
	        -Dsitescript=/usr/bin/site_perl -Dvendorscript=/usr/bin/vendor_perl \
	        -Dinc_version_list=none -Dman1ext=1perl -Dman3ext=3perl $${ARCHOPTS} \
	        -Dlddlflags="-shared $${LDFLAGS}" -Dldflags="$${LDFLAGS}" && \
	make && \
	mkdir -p ../perl-build && \
	pkgdir="$$(cd ../perl-build && pwd)" && \
	make DESTDIR="$$pkgdir" install && \
	sed -e '/^man1ext=/ s/1perl/1p/' -e '/^man3ext=/ s/3perl/3pm/' \
	    -e "/^cf_email=/ s/'.*'/''/" \
	    -e "/^perladmin=/ s/'.*'/''/" \
	    -i $${pkgdir}/usr/lib/perl$(PERL_MAJOR)/core_perl/Config_heavy.pl && \
	sed -e '/(makepl_arg =>/   s/""/"INSTALLDIRS=site"/' \
	    -e '/(mbuildpl_arg =>/ s/""/"installdirs=site"/' \
	    -i $${pkgdir}/usr/share/perl$(PERL_MAJOR)/core_perl/CPAN/FirstTime.pm && \
	sed -e "/{'makemakerflags'}/ s/'';/'INSTALLDIRS=site';/" \
	    -e "/{'buildflags'}/     s/'';/'installdirs=site';/" \
	    -i $${pkgdir}/usr/share/perl$(PERL_MAJOR)/core_perl/CPANPLUS/Config.pm && \
	install -D -m755 ../confs/perlbin.sh $${pkgdir}/etc/profile.d/perlbin.sh && \
	install -D -m755 ../confs/perlbin.csh $${pkgdir}/etc/profile.d/perlbin.csh && \
	mv $${pkgdir}/usr/bin/perl$(PERL_VERSION) $${pkgdir}/usr/bin/perl && \
	ln -sf c2ph $${pkgdir}/usr/bin/core_perl/pstruct && \
	ln -sf s2p $${pkgdir}/usr/bin/core_perl/psed && \
	rm -f $${pkgdir}/usr/share/perl$(PERL_MAJOR)/core_perl/*.pod && \
	for d in $${pkgdir}/usr/share/perl$(PERL_MAJOR)/core_perl/*; do \
	    if [ -d $$d -a $$(basename $$d) != "pod" ]; then \
	        find $$d -name *.pod -delete; \
	    fi; \
	done && \
	find $${pkgdir}/usr/lib -name *.pod -delete && \
	find $${pkgdir} -name .packlist -delete && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo cp -r "$${pkgdir}"/* "$(MNT)" && \
	sudo rm -r "$${pkgdir}"/* && \
	(sudo rmdir "$${pkgdir}" || \
	    (sudo cp -r "$${pkgdir}"/.* "$(MNT)" && sudo rm -r "$${pkgdir}")) && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

