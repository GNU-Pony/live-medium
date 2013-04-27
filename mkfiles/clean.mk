# Clean up built files
.PHONY: clean
clean:
	-sudo rm -r $(CLEAN_DIR) cpiolist *.bin built
	-sudo make -C "$(GNU_PONY_INITRAM)" clean


# Clean up built packages
.PHONY: clean-pkg
clean-pkg:
	-rm pkg/*.pkg.tar.$(PKG_COMPRESS_EXT) finalise


# Clean up built system
.PHONY: clean-mnt
clean-mnt:
	if [ "$(DEVICELESS)" = "y" ] && [ ! "$(MNT)" = "" ]; then \
	    sudo rm -r "$(MNT)" && mkdir "$(MNT)"; \
	elif [ "$(DEVICELESS)" = "" ] && [ ! "$(MNT)" = "" ]; then \
	    cd "$(MNT)" && for f in $$(echo * .*); do \
	        if [ ! "$$f" = "." ] && [ ! "$$f" = ".." ] && \
	           [ ! "$$f" = "lost+found" ] ; then \
	               sudo rm -r "$$f"; \
	    fi; done; \
	fi


# Clean everything but the built pacakges
.PHONY: clean-mostly
clean-mostly: clean clean-mnt


# Clean everything 
.PHONY: clean-all
clean-all: clean clean-pkg clean-mnt

