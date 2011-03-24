export TARGET_REMOTE := 0

ifeq ($(_THEOS_CAN_PACKAGE),1)
ifeq ($(_THEOS_PACKAGE_LAST_VERSION),none)
internal-install::
	$(info $(MAKE) install requires that you build a package before you try to install it.)
	@exit 1
else # _THEOS_PACKAGE_LAST_VERSION
internal-install::
	install.exec "dpkg -i $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb"
endif # _THEOS_PACKAGE_LAST_VERSION
else # _THEOS_CAN_PACKAGE
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "/"
endif
