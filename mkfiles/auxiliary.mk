# This is used to copy files via Arch Linux's pacman, so that package inclusion testing can be done easier
arch-packages:
	[ "$(ARCH_PACKAGES)" = "" ] || \
	sudo pacman -Ql $(ARCH_PACKAGES) | \
	        cut -d ' ' -f 2 | grep    '/$$' | while read f; do \
	            echo "mkdir -p $(MNT)$$f"; \
	            sudo mkdir -p "$(MNT)$$f"; \
	        done
	[ "$(ARCH_PACKAGES)" = "" ] || \
	sudo pacman -Ql $(ARCH_PACKAGES) | \
	        cut -d ' ' -f 2 | grep -v '/$$' | while read f; do \
	            echo "cp $$f => $(MNT)$$f"; \
	            [ -e "$(MNT)$$f" ] || \
	                sudo cp "$$f" "$(MNT)$$f"; \
	        done

# Create a tar with all files
tar-usb:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	sudo tar --create > "$(TAR_FILE)" \
	    $$(sudo find . | sed -e 's_^\./__' | cut -d / -f 1 | uniq | sort | uniq)

# Create a cpio with all files
cpio-usb:
	[ "$(DEVICELESS)" = "y" ]
	cd "$(MNT)" && \
	sudo find . | sed -e 's_^\./__' | cut -d / -f 1 | uniq | sort | uniq | \
	    sudo cpio --create > "$(CPIO_FILE)"

validate-non-root:
	[ ! "$$UID" = 0 ]

validate-device:
	if ([ "$(DEVICE)" = "" ] && [ "$(DEVICELESS)" = "y" ]); then \
	    echo -e '\e[01;33mDeviceless installation\e[21;39m'; \
	else \
	    ([ -f "/dev/$(DEVICE)" ] &&  echo -e '\e[01;32mDEVICE ok\e[21;39m') \
	                             || (echo -e '\e[01;31mno DEVICE\e[21;39m' ; exit 1); \
	fi

