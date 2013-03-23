# public domain (copyrightable inelligible)
CLEAN_DIR += "dnssec-anchors-build"
packages: dnssec-anchors
dnssec-anchors:
	mkdir -p dnssec-anchors-build
	cd dnssec-anchors-build && \
	 drill -z -s DNSKEY . > root.key
	cd dnssec-anchors-build && \
	 curl "http://data.iana.org/root-anchors/root-anchors.xml" | \
	 awk 'BEGIN{ORS=" "}(NR>4){gsub(/<[^>]*>/,"");print tolower($$0)}' | \
	 sed 's/   /\n/' > root.ds
	cd dnssec-anchors-build && \
	 [[ "$$(<root.ds)" = '19036 8 2 49aac11d7b6f6446702e54a1607371607a1a41855200fd2ce1cdde32f24e8fb5' ]] && \
	 grep -Pq 'IN\tDS\t'"$$(<root.ds)" root.key || \
	 (echo -e '\e[01;31mSuspicious dnssec-anchors\e[00m' ; exit 1)
	cd dnssec-anchors-build && \
	 sed '/DNSKEY/s/ ;{id = '"$$(cut -d\  -f1<root.ds)"' .*//;t;d' root.key > trusted-key.key
	cd dnssec-anchors-build && \
	([ "$(DEVICE)" = "" ] || sudo mount "/dev/$(DEVICE)1" "$(MNT)") && \
	sudo install -Dm644 trusted-key.key "$(MNT)"/etc/trusted-key.key && \
	sudo install -Dm644 ../patches/dnssec-anchors-license \
	        "$(MNT)"/usr/share/licenses/dnssec-anchors/LICENSE && \
	([ "$(DEVICE)" = "" ] || sudo umount "$(MNT)") && \
	cd ..

