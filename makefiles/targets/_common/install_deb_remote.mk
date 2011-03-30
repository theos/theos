export TARGET_REMOTE := 1

ifeq ($(THEOS_DEVICE_IP),)
internal-install::
	$(info $(MAKE) install requires that you set THEOS_DEVICE_IP in your environment. It is also recommended that you have public-key authentication set up for root over SSH, or you'll be entering your password a lot.)
	@exit 1
else # THEOS_DEVICE_IP

THEOS_DEVICE_PORT ?= 22

export THEOS_DEVICE_IP THEOS_DEVICE_PORT

ifeq ($(_THEOS_CAN_PACKAGE),1)
internal-install::
	@if [[ "$(_THEOS_PACKAGE_LAST_VERSION)" == "none" ]]; then \
		echo "$(MAKE) install requires that you build a package before you try to install it." >&2; \
		exit 1; \
	fi
	@if [[ ! -f "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" ]]; then \
		echo "Could not find \"$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb\" to install. Aborting." >&2; \
		exit 1; \
	fi
	install.copyFile "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" "$(THEOS_PACKAGE_FILENAME).deb"
	install.exec "dpkg -i $(THEOS_PACKAGE_FILENAME).deb"
else # _THEOS_CAN_PACKAGE == 0
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "/"
endif # _THEOS_CAN_PACKAGE

endif # THEOS_DEVICE_IP
