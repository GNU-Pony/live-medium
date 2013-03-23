# GPL
# removed files are provided by util-linux, except for the corrected (made safer) link
SYSVINIT = sysvinit-$(SYSVINIT_VERSION)dsf
CLEAN_DIR += "$(SYSVINIT)"
packages: sysvinit
sysvinit:
	[ -f "$(SYSVINIT).tar.bz2" ] || \
	wget "http://download.savannah.gnu.org/releases/sysvinit/$(SYSVINIT).tar.bz2"
	[ -d "$(SYSVINIT)" ] || \
	tar --bzip2 --get < "$(SYSVINIT).tar.bz2"
	pushd "$(SYSVINIT)" && \
	([ ! "$(SYSVINIT_SIMPLIFY_WRITELOG)" = "y" ] || \
	        patch -p1 -d "src" -i ../../patches/0001-simplify-writelog.patch) && \
	([ "$(SYSVINIT_ANSI)" = "y" ] || \
	        patch -p1 -d "src" -i ../../patches/0002-remove-ansi-escape-codes-from-log-file.patch) && \
	make && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo mkdir -p "$(MNT)/__pony_temp__" && \
	sudo make ROOT="$(MNT)/__pony_temp__" install && \
	cd "$(MNT)/__pony_temp__" && \
	sudo rm bin/pidof && \
	sudo ln -sf ../sbin/killall5 bin/pidof && \
	sudo rm bin/mountpoint \
	   sbin/sulogin \
	   usr/bin/{mesg,utmpdump,wall} \
	   usr/share/man/man?/{mesg,mountpoint,sulogin,utmpdump,wall}.? && \
	( \
	    find ./ | while read file; do \
	        if [ -d "$$file" ]; then \
	            echo 'moving directory '"$$file"; \
	            sudo mkdir -p ."$$file"; \
	        else \
	            echo 'moving file '"$$file"; \
	            sudo cp -d "$$file" ."$$file"; \
	        fi; \
	    done \
	) && \
	cd .. && \
	sudo rm -r __pony_temp__ && \
	popd && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

