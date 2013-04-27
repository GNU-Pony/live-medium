.PHONY: clean
clean:
	-sudo rm -r $(CLEAN_DIR) cpiolist *.bin built
	-sudo make -C "$(GNU_PONY_INITRAM)" clean

.PHONY: clean-download
clean-download:
	-rm -r *.{tar{,.gz,.bz2,.xz},tgz}
	-rm -r {bash,readline}??-???

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


.PHONY: clean-mostly
clean-mostly: clean clean-mnt

.PHONY: clean-all
clean-all: clean clean-download clean-mnt

