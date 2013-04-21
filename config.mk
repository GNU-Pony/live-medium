ARCH = x86_64
KERNEL_ARCH = $(ARCH)
CPUS = 16 # how many CPU:s you want to use when compiling

CHOST = $(ARCH)-unknown-linux-gnu

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

