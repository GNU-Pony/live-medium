# TODO: do error check on gmp
# TODO: libedit is in critical need of patch for non-ASCII character support
# TODO: use linux-libre


# Edit config.mk if you want to change a configuration
# or use another architecture than x86_64
include config.mk


# This is used to copy files via Arch Linux's pacman,
# so that package inclusion testing can be done easier
ARCH_PACKAGES = 

KERNEL_VERSION = 3.8.3
MEMTEST_VERSION = 4.20

include mkfiles/auxiliary-config.mk
include versions.mk


all:	validate-non-root			\
	kernel					\
	initramfs-linux update-init init-live	\
	essentials arch-packages packages	\
	local conf-override			\
	chown-live


include mkfiles/kernel.mk
include mkfiles/boot.mk
include mkfiles/essentials.mk

# Each file starts with a list of licenses that
# applies the the package installed by its rule
include pkgs/acl.mk
include pkgs/attr.mk
include pkgs/cracklib.mk
include pkgs/expat.mk
include pkgs/file.mk
include pkgs/hwids.mk
include pkgs/less.mk
include pkgs/libcap.mk
include pkgs/libgpg-error.mk
include pkgs/libnl.mk
include pkgs/libssh2.mk
include pkgs/libusbx.mk
include pkgs/ncurses.mk
include pkgs/netcfg.mk
include pkgs/pcre.mk
include pkgs/popt.mk
include pkgs/sysfsutils.mk
include pkgs/xz.mk
include pkgs/zlib.mk
include pkgs/ldns.mk
include pkgs/keyutils.mk
include pkgs/which.mk
include pkgs/tar.mk
include pkgs/sed.mk
include pkgs/nano.mk
include pkgs/coreutils.mk
include pkgs/db.mk
include pkgs/findutils.mk
include pkgs/gawk.mk
include pkgs/gettext.mk
include pkgs/gmp.mk
include pkgs/libffi.mk
include pkgs/libgcrypt.mk
include pkgs/bzip2.mk
include pkgs/gdbm.mk
include pkgs/glib2.mk
include pkgs/grep.mk
include pkgs/gzip.mk
include pkgs/iproute2.mk
include pkgs/texinfo.mk
include pkgs/sysvinit.mk
include pkgs/openssl.mk
include pkgs/libtirpc.mk
include pkgs/libpcap.mk
include pkgs/libgssglue.mk
include pkgs/readline.mk
include pkgs/kmod.mk
include pkgs/e2fsprogs.mk
include pkgs/bash.mk
include pkgs/libsasl.mk
include pkgs/gcc-libs.mk
include pkgs/initscripts-fork.mk
include pkgs/curl.mk
include pkgs/iana-etc.mk
include pkgs/cryptsetup.mk
include pkgs/dbus.mk
include pkgs/dhcpcd.mk
include pkgs/libedit.mk
include pkgs/openssh.mk
include pkgs/perl.mk
include pkgs/krb5.mk
include pkgs/iputils.mk
include pkgs/openntpd.mk
include pkgs/inetutils.mk
include pkgs/libldap.mk
include pkgs/device-mapper.mk
include pkgs/systemd.mk
include pkgs/kbd.mk
include pkgs/glibc.mk
include pkgs/pam.mk
include pkgs/pam_unix.mk
include pkgs/shadow.mk
include pkgs/util-linux.mk
include pkgs/tzdata.mk
include pkgs/dnssec-anchors.mk

include mkfiles/auxiliary.mk
include mkfiles/local.mk
include mkfiles/clean.mk

