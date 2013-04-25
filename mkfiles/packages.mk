PACKAGES = $(shell find pkgs/ | grep '\.scroll$$' | grep -v '\x23' | sed -e 's:^pkgs/::g' -e 's:\.scroll$$::g' | sort)

CLEAN_DIR += $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE))

packages: $(foreach PACKAGE, $(PACKAGES), pkgs/$(PACKAGE).pkg.tar.$(PKG_COMPRESS_EXT))

pkgs/%.pkg.tar.$(PKG_COMPRESS_EXT): pkgs/%.scroll
	mkdir -p "pkgs/$*/start" "pkgs/$*/install"
	ARCH=$(ARCH) HOST=$(HOST) MAKEFLAGS= "$(SPIKE)/spikeless" "pkgs/$*.scroll" "pkgs/$*/start" "pkgs/$*/install"
	cd "pkgs/$*/install" && tar --create * | $(PKG_COMPRESS) > "../../$*.pkg.tar.$(PKG_COMPRESS_EXT)"

