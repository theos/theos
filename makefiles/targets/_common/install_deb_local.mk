export TARGET_REMOTE := 0

ifeq ($(_THEOS_CAN_PACKAGE),$(_THEOS_TRUE))
internal-install::
	@if [[ "$(_THEOS_PACKAGE_LAST_VERSION)" == "none" ]]; then \
		echo "$(MAKE) install requires that you build a package before you try to install it." >&2; \
		exit 1; \
	fi
	@if [[ ! -f "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" ]]; then \
		echo "Could not find \"$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb\" to install. Aborting." >&2; \
		exit 1; \
	fi
	install.exec "dpkg -i $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb"
else # _THEOS_CAN_PACKAGE
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "/"
endif
