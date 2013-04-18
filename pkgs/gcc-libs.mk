# GPL, LGPL, FDL, custom (free exception)
# split packages: gcc-libs
GCC_LIBS = gcc-$(GCC_LIBS_VERSION)
CLEAN_DIR += "$(GCC_LIBS)" "gcc-build"
packages: gcc-libs
gcc-libs:
	[ -f "$(GCC_LIBS).tar.bz2" ] || \
	wget "ftp://gcc.gnu.org/pub/gcc/releases/$(GCC_LIBS)/$(GCC_LIBS).tar.bz2"
	[ -d "$(GCC_LIBS)" ] || \
	tar --bzip2 --get < "$(GCC_LIBS).tar.bz2"
	cd "$(GCC_LIBS)" && \
	sed -i 's/install_to_$$(INSTALL_DEST) //' libiberty/Makefile.in && \
	sed -i 's_\./fixinc\.sh_-c true_' gcc/Makefile.in && \
	([ ! "$(ARCH)" = "x86_64" ] || sed -i '/m64=/s/lib64/lib/' gcc/config/i386/t-linux64) && \
	patch -p1 -i ../patches/gcc-4.7.1-libgo-write.patch && \
	echo 4.7.2 > gcc/BASE-VER && \
	export CFLAGS=" -O2 -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" && \
	export CXXFLAGS=" -O2 -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2" && \
	mkdir -p ../gcc-build && cd ../gcc-build && \
	../gcc-4.7.2/configure --prefix=/usr --libdir=/usr/lib --libexecdir=/usr/libexec \
	         --mandir=/usr/share/man --infodir=/usr/share/info--enable-languages=c,c++,fortran,lto \
	        --enable-shared --enable-threads=posix --with-system-zlib --enable-__cxa_atexit \
	        --disable-libunwind-exceptions --enable-clocale=gnu --disable-libstdcxx-pch \
	        --enable-libstdcxx-time --enable-gnu-unique-object --enable-linker-build-id \
	        --with-ppl --enable-cloog-backend=isl --disable-ppl-version-check \
	        --disable-cloog-version-check --enable-lto --enable-gold --enable-ld=default \
	        --enable-plugin --with-plugin-ld=ld.gold --with-linker-hash-style=gnu --disable-multilib \
	        --disable-libssp --disable-build-with-cxx --disable-build-poststage1-with-cxx \
	        --enable-checking=release && \
	cd ..
	sed -i 's|@itemx --help|@item --help|g' $(GCC_LIBS)/gcc/doc/cppopts.texi
	for t in '-fenable-@var{kind}-@var{pass}' '-fdump-rtl-cprop_hardreg' '-fdump-rtl-csa' \
	         '-fdump-rtl-dce' '-fdump-rtl-dbr' '-fdump-rtl-into_cfglayout' \
	         '-fdump-rtl-outof_cfglayout' '-fdump-rtl-pro_and_epilogue'; do \
	    sed -i "s|@itemx $${t}|@item $${t}|g" $(GCC_LIBS)/gcc/doc/invoke.texi || exit 1; \
	done
	sed -i "s|@tie{KiB}|@tie{}KiB|g" $(GCC_LIBS)/gcc/doc/invoke.texi
	sed -i "s|@itemx all.cross|@item all.cross|g" $(GCC_LIBS)/gcc/doc/sourcebuild.texi
	sed -i "s|@itemx POINTER_PLUS_EXPR|@item POINTER_PLUS_EXPR|g" $(GCC_LIBS)/gcc/doc/generic.texi
	sed -i "s|@itemx PLUS_EXPR|@item PLUS_EXPR|g" $(GCC_LIBS)/gcc/doc/generic.texi
	cd gcc-build && make && cd ..
	cd gcc-build/$(CHOST)/libstdc++-v3 && \
	make doc-man-doxygen && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && cd ../..
	cd gcc-build && \
	sudo make -j1 -C $(CHOST)/libgcc DESTDIR="$(MNT)" install-shared && cd ..
	cd gcc-build && \
	for lib in libmudflap libgomp libstdc++-v3/src libitm; do \
	    sudo make -j1 -C $(CHOST)/$$lib DESTDIR="$(MNT)" install-toolexeclibLTLIBRARIES; \
	done && cd ..
	cd gcc-build && \
	sudo make -j1 -C $(CHOST)/libstdc++-v3/po DESTDIR="$(MNT)" install && cd ..
	cd gcc-build && \
	sudo make -j1 -C $(CHOST)/libgomp DESTDIR="$(MNT)" install-info && \
	sudo make -j1 -C $(CHOST)/libitm DESTDIR="$(MNT)" install-info && cd ..
	cd gcc-build && \
	sudo make -j1 DESTDIR="$(MNT)" install-target-lib{quadmath,gfortran,objc} && cd ..
	cd gcc-build && \
	sudo rm -r "$(MNT)"/usr/lib/{gcc/,libgfortran.spec} && \
	sudo find "$(MNT)" -name *.a -delete && \
	sudo install -Dm644 ../$(GCC_LIBS)/COPYING.RUNTIME \
	        "$(MNT)"/usr/share/licenses/gcc-libs/RUNTIME.LIBRARY.EXCEPTION && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

