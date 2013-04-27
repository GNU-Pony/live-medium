# Machine arch
ARCH = $(shell uname -m)

# Kernel arch
KERNEL_ARCH = $(ARCH)

# How many CPU:s you want to use when compiling
CPUS = 16


# Bootloader background
BOOT_SPLASH = ./boot/splash.png

# Bootloader configurations
BOOT_CONFIG = ./boot/syslinux.cfg


# USB tar file
TAR_FILE = ../live-usb-files.tar

# USB cpio file
CPIO_FILE = ../live-usb-files.cpio


# Kernel configurations
KERNEL_CONFIG = kernelconf/kernel.mini.config
# kernelconf/kernel.mini.config
# kernelconf/kernel.hpc.config
# kernelconf/kernel.config


# USB file system label
USB_LABEL = GNU_PONY

# USB file system type
USB_FS = ext2

# USB file system mount point
MNT = /mnt

