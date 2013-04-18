# public domain
# note: it is still common for servers to encounter fatal problems on leapseconds,
#       if you are running a server my may consider freezing this package so no
#       upcoming leapseconds are registrered on the local leapseconds register.
TZDATA = tzdata-$(TZDATA_VERSION)
TZDATA_ = tzdata$(TZDATA_VERSION)
CLEAN_DIR += "$(TZDATA)"
packages: tzdata
tzdata:
	[ -f "$(TZDATA).tar.gz" ] || \
	wget "http://www.iana.org/time-zones/repository/releases/$(TZDATA_).tar.gz" -O $(TZDATA).tar.gz
	[ -d "$(TZDATA)" ] || \
	mkdir -p "$(TZDATA)" && cd "$(TZDATA)" && \
	tar --gzip --get < "../$(TZDATA).tar.gz" && \
	timezones=('africa' 'antarctica' 'asia' 'australasia' 'europe' 'northamerica' 'southamerica' \
	           'pacificnew' 'etcetera' 'backward' 'systemv' 'factory' 'solar87' 'solar88' 'solar89') && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo zic -y ./yearistype -d "$(MNT)"/usr/share/zoneinfo $${timezones[@]} && \
	sudo zic -y ./yearistype -d "$(MNT)"/usr/share/zoneinfo/posix $${timezones[@]} && \
	sudo zic -y ./yearistype -d "$(MNT)"/usr/share/zoneinfo/right -L leapseconds $${timezones[@]} && \
	sudo zic -y ./yearistype -d "$(MNT)"/usr/share/zoneinfo -p America/New_York && \
	sudo install -m444 -t "$(MNT)"/usr/share/zoneinfo iso3166.tab zone.tab && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..
	echo "[$@]" >> built

