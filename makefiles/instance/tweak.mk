ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tweak-all_ internal-tweak-package_

LOCAL_INSTALL_PATH ?= $(strip $($(FW_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
endif

AUXILIARY_LDFLAGS += -lsubstrate

include $(FW_MAKEDIR)/instance/library.mk

internal-tweak-all_:: internal-library-all_

internal-tweak-package_:: internal-library-package_
