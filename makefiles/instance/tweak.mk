ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tweak-all_ internal-tweak-stage_

LOCAL_INSTALL_PATH ?= $(strip $($(FW_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
endif

AUXILIARY_LDFLAGS += -lsubstrate

include $(FW_MAKEDIR)/instance/library.mk

internal-tweak-all_:: internal-library-all_

internal-tweak-stage_:: internal-library-stage_
	$(ECHO_NOTHING)if [ -f $(FW_INSTANCE).plist ]; then cp $(FW_INSTANCE).plist "$(FW_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"; fi$(ECHO_END)
