# BSD
NETCFG = netcfg-$(NETCFG_VERSION)
CLEAN_DIR += "$(NETCFG)"
packages: netcfg
netcfg:
	[ -f "$(NETCFG).tar.xz" ] || \
	wget "ftp://ftp.archlinux.org/other/netcfg/$(NETCFG).tar.xz"
	[ -d "$(NETCFG)" ] || \
	tar --xz --get < "$(NETCFG).tar.xz"
	cd "$(NETCFG)" && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo make DESTDIR="$(MNT)" install && \
	sudo install -D -m644 LICENSE "$(MNT)"/usr/share/licenses/netcfg/LICENSE && \
	sudo install -D -m644 contrib/bash-completion "$(MNT)"/usr/share/bash-completion/completions/netcfg && \
	sudo install -D -m644 contrib/zsh-completion "$(MNT)"/usr/share/zsh/site-functions/_netcfg && \
	sudo ln -sf netcfg.service "$(MNT)"/usr/lib/systemd/system/net-profiles.service && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

