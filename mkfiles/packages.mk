PACKAGES = $(shell find pkgs/ | grep '\.scroll$$' | grep -v '\x23' | sed -e 's:^pkgs/::g' -e 's:\.scroll$$::g' | sort)

CLEAN_DIR += $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE))


clean-finalise:
	-rm finalise
	echo '#!/bin/sh' > finalise
	chmod a+x finalise


finalise-packages:
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; sudo $$root/finalise
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")


pkgs/%.pkg.tar.$(PKG_COMPRESS_EXT): pkgs/%.scroll clean-finalise
	mkdir -p "pkgs/$*/start" "pkgs/$*/install"
	PATH="$$(realpath ./tools):$${PATH}" ARCH=$(ARCH) HOST=$(HOST) MAKEFLAGS= \
	    "$(SPIKE)/spikeless" "pkgs/$*.scroll" "pkgs/$*/start" "pkgs/$*/install"
	cd "pkgs/$*/install" && tar --create * | $(PKG_COMPRESS) > "../../$*.pkg.tar.$(PKG_COMPRESS_EXT)"


packages: $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE).pkg.tar.$(PKG_COMPRESS_EXT))
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; for pkg in $(foreach PKG, $(PKGS_STAGE_1), pkgs/$(PKG).pkg.tar.$(PKG_COMPRESS_EXT)); do \
	echo "extracting $$pkg" ; tar --get --xz < $$root/$$pkg ; done
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")

