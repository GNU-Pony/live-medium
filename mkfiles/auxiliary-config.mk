# The GNU/Pony initramfs directory
GNU_PONY_INITRAM = ../initram

# The GNU/Pony package manager directory
SPIKE = ../spike

# Host string
HOST = $(ARCH)-unknown-linux-gnu

# Kernel mirror
KERNEL_MIRROR = https://ftp.kernel.org/pub/linux

# SYSLINUX directory
SYSLINUX_DIR = /usr/lib/syslinux

# Boot manager
MBR = $(SYSLINUX_DIR)/mbr.bin


# Initcpio compression command
INITCPIO_COMPRESS = gzip -9

# Package archive file compression command
PKG_COMPRESS = xz -e9

# Package archive file compression extension, e.g. gz
PKG_COMPRESS_EXT = xz

# Package archive file compression name, e.g. gzip
PKG_DECOMPRESS_EXT = xz

# PATH environment variable for the live medium
PATH = /usr/local/bin:/usr/local/sbin:/usr/local/libexec:/usr/bin:/usr/sbin:/usr/libexec:/bin:/sbin:/libexec


# Directories to remove at clean up
CLEAN_DIR =


# Group ID:s
utmp=20
ftp=11
games=50
root=0

