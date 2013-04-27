# TODO: do error check on gmp
# TODO: libedit is in critical need of patch for non-ASCII character support
# TODO: use linux-libre


# This is used to copy files via Arch Linux's pacman,
# so that package inclusion testing can be done easier
ARCH_PACKAGES = 

KERNEL_VERSION = 3.8.3
MEMTEST_VERSION = 4.20


include mkfiles/config.mk
include mkfiles/auxiliary-config.mk


all:	validate-non-root				\
	kernel arch-packages packages			\
	initramfs-linux update-init init-live		\
	essentials install-packages conf-override	\
	chown-live finalise-packages			\
	create-users


include mkfiles/kernel.mk
include mkfiles/boot.mk
include mkfiles/essentials.mk
include mkfiles/packages.mk
include mkfiles/auxiliary.mk
include mkfiles/clean.mk

