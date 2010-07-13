export TARGET_REMOTE := 1

ifeq ($(FW_DEVICE_IP),)
internal-install::
	$(info $(MAKE) install requires that you set FW_DEVICE_IP in your environment. It is also recommended that you have public-key authentication set up for root over SSH, or you'll be entering your password a lot.)
	@exit 1
else # FW_DEVICE_IP

FW_DEVICE_PORT ?= 22

export FW_DEVICE_IP FW_DEVICE_PORT

ifeq ($(FW_CAN_PACKAGE),1)
internal-install::
	install.copyFile "$(FW_PROJECT_DIR)/$(FW_PACKAGE_FILENAME).deb" "$(FW_PACKAGE_FILENAME).deb"
	install.exec "dpkg -i $(FW_PACKAGE_FILENAME).deb"
else # FW_CAN_PACKAGE == 0
internal-install:: stage
	install.mergeDir "$(FW_STAGING_DIR)" "/"
endif # FW_CAN_PACKAGE

endif # FW_DEVICE_IP
