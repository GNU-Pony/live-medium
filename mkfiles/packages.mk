PKGS_STAGE_1 = acl attr audit bash bzip2 coreutils cracklib cryptsetup curl db dbus device-mapper \
               dhcpcd dnssec-anchors e2fsprogs expat file findutils gawk gdbm gettext glib2 glibc \
               gmp grep gzip hwids iana-etc inetutils initscripts-fork iproute2 iputils kbd keyutils \
               kmod krb5 ldns less libcap libedit libffi libgcrypt libgpg-error libgssglue libldap \
               libnl libpcap libssh2 libtirpc libusbx nano ncurses netcfg openntpd openssh openssl \
               pam pam_unix pcre perl popt readline sed shadow sysfsutils systemd sysvinit tar \
               texinfo tzdata util-linux which xz zlib

PKGS_STAGE_2 = gcc-libs libsasl


PKGS = $(PKGS_STAGE_1) $(PKGS_STAGE_2)
CLEAN_DIR += $(foreach PKG, $(PKGS), pkgs/$(PKG))


packages: clean-finalise packages-stage1 packages-stage2


clean-finalise:
	-rm finalise
	echo '#!/bin/sh' > finalise
	chmod a+x finalise


finalise-packages:
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; sudo $$root/finalise
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")


pkgs/%.pkg.tar.$(PKG_COMPRESS_EXT): pkgs/%.scroll
	mkdir -p "pkgs/$*/start" "pkgs/$*/install"
	PATH="$$(realpath ./tools):$${PATH}" ARCH=$(ARCH) HOST=$(HOST) MAKEFLAGS= \
	    "$(SPIKE)/spikeless" "pkgs/$*.scroll" "pkgs/$*/start" "pkgs/$*/install"
	cd "pkgs/$*/install" && tar --create * | $(PKG_COMPRESS) > "../../$*.pkg.tar.$(PKG_COMPRESS_EXT)"


packages-build-stage1: $(foreach PKG, $(PKGS_STAGE_1), pkgs/$(PKG).pkg.tar.$(PKG_COMPRESS_EXT))
packages-build-stage2: $(foreach PKG, $(PKGS_STAGE_2), pkgs/$(PKG).pkg.tar.$(PKG_COMPRESS_EXT))


packages-stage1:
	make -j$(CPUS) packages-build-stage1
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; for pkg in $(foreach PKG, $(PKGS_STAGE_1), pkgs/$(PKG).pkg.tar.$(PKG_COMPRESS_EXT)); do \
	echo "extracting $$pkg" ; tar --get --xz < $$root/$$pkg ; done
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")


packages-stage2:
	LD_LIBRARY_PATH="$(MNT)" make -j$(CPUS) packages-build-stage2
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; for pkg in $(foreach PKG, $(PKGS_STAGE_2), pkgs/$(PKG).pkg.tar.$(PKG_COMPRESS_EXT)); do \
	echo "extracting $$pkg" ; tar --get --xz < $$root/$$pkg ; done
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")

