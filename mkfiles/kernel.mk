KERNEL_VERSION_CAT = $(shell echo $(KERNEL_VERSION) | cut -d . -f 1).0
KERNEL = linux-$(KERNEL_VERSION)
CLEAN_DIR += $(KERNEL)

kernel: $(KERNEL)/vmlinux

$(KERNEL).tar.xz:
	wget '$(KERNEL_MIRROR)/kernel/v$(KERNEL_VERSION_CAT)/$(KERNEL).tar.xz' $(KERNEL_CERT)

$(KERNEL): $(KERNEL).tar.xz
	tar --get --xz < "$(KERNEL).tar.xz"

$(KERNEL)/.config: $(KERNEL)
	if [ ! -f "$(KERNEL)/.config" ]; then \
	    cp "$(KERNEL_CONFIG)" "$(KERNEL)/.config"; \
	fi
	make -C "$(KERNEL)" prepare
	make -C "$(KERNEL)" nconfig
	yes "" | make -C "$(KERNEL)" config > /dev/null

$(KERNEL)/vmlinux: $(KERNEL)/.config
	make -j$(CPUS) -C "$(KERNEL)"

