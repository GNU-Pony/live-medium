GNU_PONY_INITRAM = ../initram
HOST = $(ARCH)-unknown-linux-gnu
KERNEL_MIRROR = https://ftp.kernel.org/pub/linux
SYSLINUX_DIR = /usr/lib/syslinux
MBR = $(SYSLINUX_DIR)/mbr.bin
INITCPIO_COMPRESS = xz -e9
CLEAN_DIR =

utmp=20
ftp=11
games=50
root=0

