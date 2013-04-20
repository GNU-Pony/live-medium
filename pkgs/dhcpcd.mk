# BSD
DHCPCD = dhcpcd-$(DHCPCD_VERSION)
CLEAN_DIR += "$(DHCPCD)"
packages: dhcpcd
dhcpcd:
	[ -f "$(DHCPCD).tar.bz2" ] || \
	wget "http://roy.marples.name/downloads/dhcpcd/$(DHCPCD).tar.bz2"
	[ -d "$(DHCPCD)" ] || \
	tar --bzip2 --get < "$(DHCPCD).tar.bz2"
	cd "$(DHCPCD)" && \
	./configure --libexecdir=/usr/lib/dhcpcd --dbdir=/var/lib/dhcpcd --rundir=/run && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo mkdir -p "$(MNT)"/usr/sbin && \
	sudo ln -sf /sbin/dhcpcd "$(MNT)"/usr/sbin/dhcpcd && \
	sudo install -D -m644 ../confs/dhcpcd.conf.d "$(MNT)"/etc/conf.d/dhcpcd && \
	sudo mkdir -p "$(MNT)"/usr/share/licenses/dhcpcd && \
	sudo sh -c \
	  'awk '\''{if(FNR<27)print $$0}'\'' ./configure.h >> "$(MNT)"/usr/share/licenses/dhcpcd/LICENSE' && \
	sudo sh -c 'echo noipv4ll >> "$(MNT)"/etc/dhcpcd.conf' && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

