export TARGET_REMOTE := 1

ifeq ($(THEOS_DEVICE_IP),)
internal-install::
	$(info $(MAKE) install requires that you set THEOS_DEVICE_IP in your environment. It is also recommended that you have public-key authentication set up for root over SSH, or you'll be entering your password a lot.)
	@exit 1
else # THEOS_DEVICE_IP

THEOS_DEVICE_PORT ?= 22

export THEOS_DEVICE_IP THEOS_DEVICE_PORT

ifeq ($(_THEOS_CAN_PACKAGE),1)
ifeq ($(_THEOS_PACKAGE_LAST_VERSION),none)
internal-install::
	$(info $(MAKE) install requires that you build a package before you try to install it.)
	@exit 1
else # _THEOS_PACKAGE_LAST_VERSION
internal-install::
	install.copyFile "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" "$(THEOS_PACKAGE_FILENAME).deb"
	install.exec "dpkg -i $(THEOS_PACKAGE_FILENAME).deb"
endif # _THEOS_PACKAGE_LAST_VERSION
else # _THEOS_CAN_PACKAGE == 0
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "/"
endif # _THEOS_CAN_PACKAGE

endif # THEOS_DEVICE_IP
