export TARGET_REMOTE := 0

ifeq ($(FW_CAN_PACKAGE),1)
internal-install::
	install.exec "dpkg -i $(FW_PACKAGE_FILENAME).deb"
else # FW_CAN_PACKAGE
internal-install:: stage
	install.mergeDir "$(FW_STAGING_DIR)" "/"
endif
