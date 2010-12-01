export TARGET_REMOTE := 0

ifeq ($(_THEOS_CAN_PACKAGE),1)
internal-install::
	install.exec "dpkg -i $(THEOS_PACKAGE_FILENAME).deb"
else # _THEOS_CAN_PACKAGE
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "/"
endif
