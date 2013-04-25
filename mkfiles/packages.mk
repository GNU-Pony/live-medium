PACKAGES = $(shell find pkgs/ | grep '\.scroll$$' | grep -v '\x23' | sed -e 's:^pkgs/::g' -e 's:\.scroll$$::g')

CLEAN_DIR += $(foreach $(PACKAGES), PACKAGE, pkgs/$(PACKAGE))

packages: $(foreach $(PACKAGES), PACKAGE, $(PACKAGE).pkgs.tar.$(PKG_COMPRESS_EXT))

%s.pkg.tar.$(PKG_COMPRESS_EXT): pkgs/%s.scroll
	mkdir -p "pkgs/$*/start" "pkgs/$*/install"
	ARCH=$(ARCH) HOST=$(HOST) "$(SPIKE)/spikeless" "$<" "pkgs/$*/start" "pkgs/$*/install"
	cd "pkgs/$*/install" && tar --create * | $(PKG_COMPRESS) > "$*.pkg.tar.$(PKG_COMPRESS_EXT)"

