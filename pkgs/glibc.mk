# GPL, LGPL
GLIBC = glibc-$(GLIBC_VERSION)
CLEAN_DIR += "$(GLIBC)" "glibc-build"
packages: glibc
glibc:
	export CFLAGS="-O2 -pipe --param=ssp-buffer-size=4" && \
	export LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro" && \
	[ -f "$(GLIBC).tar.xz" ] || \
	wget "http://ftp.gnu.org/gnu/libc/$(GLIBC).tar.xz"
	[ -d "$(GLIBC)" ] || \
	tar --xz --get < "$(GLIBC).tar.xz"
	[ ! -d "glibc-build" ] || rm -r "glibc-build"
	mkdir "glibc-build"
	cd "$(GLIBC)" && patch -p1 -i ../patches/glibc-2.17-sync-with-linux37.patch && cd ..
	cd "glibc-build" && \
	unset LD_LIBRARY_PATH && \
	echo "slibdir=/usr/lib" >> configparms && \
	"../$(GLIBC)/configure" --prefix="/usr" --libdir="/usr/lib" --libexecdir="/usr/libexec" \
		--with-headers="/usr/include" --enable-add-ons=nptl,libidn --enable-obsolete-rpc \
	        --enable-kernel=2.6.32 --enable-bind-now --disable-profile \
	        --enable-stackguard-randomization --enable-multi-arch && \
	echo "build-programs=no" >> configparms && \
	make && \
	sed -i "/build-programs=/s#no#yes#" configparms && \
	echo "CC += -fstack-protector -D_FORTIFY_SOURCE=2" >> configparms && \
	echo "CXX += -fstack-protector -D_FORTIFY_SOURCE=2" >> configparms && \
	make && \
	sed -i '2,4d' configparms && \
	sudo touch $(MNT)/etc/ld.so.conf && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make install_root="$(MNT)" install && \
	cd ..
	sudo rm -f "$(MNT)"/etc/ld.so.{cache,conf}
	sudo install -dm755 "$(MNT)"/usr/lib/{locale,systemd/system,tmpfiles.d}
	sudo install -m644 "$(GLIBC)"/nscd/nscd.conf "$(MNT)"/etc/nscd.conf
	sudo install -m644 confs/nscd.tmpfiles "$(MNT)"/usr/lib/tmpfiles.d/nscd.conf
	sudo install -m644 "$(GLIBC)"/posix/gai.conf "$(MNT)"/etc/gai.conf
	sudo install -m755 patches/locale-gen "$(MNT)"/usr/bin
	([ "$$(realpath "$(MNT)/sbin")" = "$$(realpath "$(MNT)/usr/bin")" ] || \
	        sudo ln -sf ../../sbin/ldconfig "$(MNT)"/usr/bin/ldconfig)
	sudo strip --strip-all \
	        "$(MNT)"/sbin/{ldconfig,sln} \
	        "$(MNT)"/usr/bin/{gencat,getconf,getent,iconv,locale,localedef} \
	        "$(MNT)"/usr/bin/{makedb,pcprofiledump,pldd,rpcgen,sprof} \
	        "$(MNT)"/usr/sbin/{iconvconfig,nscd}
	sudo strip --strip-debug "$(MNT)"/usr/lib/*.a
	sudo strip --strip-unneeded \
	        "$(MNT)"/usr/lib/{libanl,libBrokenLocale,libcidn,libcrypt}-*.so \
	        "$(MNT)"/usr/lib/libnss_{compat,db,dns,files,hesiod,nis,nisplus}-*.so \
	        "$(MNT)"/usr/lib/{libdl,libm,libnsl,libresolv,librt,libutil}-*.so \
	        "$(MNT)"/usr/lib/{libmemusage,libpcprofile,libSegFault}.so \
	        "$(MNT)"/usr/lib/{audit,gconv}/*.so
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")
	echo "[$@]" >> built

