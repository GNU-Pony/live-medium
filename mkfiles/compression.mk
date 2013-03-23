compress-live: upx-live

upx-live:
	sudo find "$(MNT)" | while read f; do if sudo [ ! -d "$$f" ]; then \
	    sudo upx $(UPX_COMPRESSION_LEVEL) "$$f" || true; \
	fi; done

