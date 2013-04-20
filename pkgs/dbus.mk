# GPL, custom (free)
DBUS = dbus-$(DBUS_VERSION)
CLEAN_DIR += "$(DBUS)"
packages: dbus
dbus:
	[ -f "$(DBUS).tar.gz" ] || \
	wget "http://dbus.freedesktop.org/releases/dbus/$(DBUS).tar.gz"
	[ -d "$(DBUS)" ] || \
	tar --gzip --get < "$(DBUS).tar.gz"
	cd "$(DBUS)" && \
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --libexecdir=/usr/libexec \
	        --with-dbus-user=dbus --with-system-pid-file=/run/dbus/pid \
	        --with-system-socket=/run/dbus/system_bus_socket --with-console-auth-dir=/run/console/ \
	        --enable-inotify --disable-dnotify --disable-verbose-mode --disable-static \
	        --disable-tests --disable-asserts --with-systemdsystemunitdir=/usr/lib/systemd/system \
	        --enable-systemd && \
	patch -p1 < ../patches/systemd-user-session.patch && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	([ ! -d "$(MNT)"/var/run ] || sudo mv "$(MNT)"/var/run "$(MNT)"/var/run--dbus ) && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo rm -rf "$(MNT)"/var/run && \
	([ ! -d "$(MNT)"/var/run--dbus ] || sudo mv "$(MNT)"/var/run--dbus "$(MNT)"/var/run ) && \
	sudo install -Dm755 ../confs/dbus "$(MNT)"/etc/rc.d/dbus && \
	sudo install -Dm755 ../confs/30-dbus "$(MNT)"/etc/X11/xinit/xinitrc.d/30-dbus && \
	sudo install -Dm644 COPYING "$(MNT)"/usr/share/licenses/dbus/COPYING && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

