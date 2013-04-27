# Packages to install
PACKAGES = $(shell find pkgs/ | grep '\.scroll$$' | grep -v '\x23' | sed -e 's:^pkgs/::g' -e 's:\.scroll$$::g' | sort)

# Package directories to remove at clean up
CLEAN_DIR += $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE))


# Clean the finalise command
clean-finalise:
	-rm finalise
	echo '#!/bin/sh' > finalise
	chmod a+x finalise


# Run the finalise command
finalise-packages:
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; sudo $$root/finalise
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")


# Build a package
pkgs/%.pkg.tar.$(PKG_COMPRESS_EXT): pkgs/%.scroll
	mkdir -p "pkgs/$*/start" "pkgs/$*/install"
	PATH="$$(realpath ./tools):$${PATH}" ARCH=$(ARCH) HOST=$(HOST) MAKEFLAGS= \
	    "$(SPIKE)/spikeless" "pkgs/$*.scroll" "pkgs/$*/start" "pkgs/$*/install"
	cd "pkgs/$*/install" && tar --create * | $(PKG_COMPRESS) > "../../$*.pkg.tar.$(PKG_COMPRESS_EXT)"


# Build packages
packages: clean-finalise
	make -j$(CPUS) $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE).pkg.tar.$(PKG_COMPRESS_EXT))


# Install packages
install-packages: $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE).pkg.tar.$(PKG_COMPRESS_EXT))
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)")
	root=$$(pwd) ; cd "$(MNT)" ; for pkg in $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE).pkg.tar.$(PKG_COMPRESS_EXT)); do \
	echo "extracting $$pkg" ; sudo tar --get --xz < $$root/$$pkg ; done
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)")

