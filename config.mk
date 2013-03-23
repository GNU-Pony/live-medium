ARCH = x86_64
KERNEL_ARCH = $(ARCH)

SYSVINIT_SIMPLIFY_WRITELOG = y
SYSVINIT_ANSI = n

BOOT_SPLASH = ./boot/splash.png
BOOT_CONFIG = ./boot/syslinux.cfg

TAR_FILE = ../live-usb-files.tar
CPIO_FILE = ../live-usb-files.cpio

KERNEL_CONFIG = kernelconf/kernel.mini.config
# kernelconf/kernel.mini.config
# kernelconf/kernel.config

USB_LABEL = GNU_PONY
USB_FS = ext2
MNT = /mnt

