GNU_PONY_INITRAM = ../initram
CHOST = $(ARCH)-unknown-linux-gnu
KERNEL_MIRROR = https://ftp.kernel.org/pub/linux
SYSLINUX_DIR = /usr/lib/syslinux
MBR = $(SYSLINUX_DIR)/mbr.bin
INITCPIO_COMPRESS = xz -e9
CLEAN_DIR =
