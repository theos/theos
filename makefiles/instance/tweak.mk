ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

.PHONY: internal-tweak-all_ internal-tweak-stage_

LOCAL_INSTALL_PATH ?= $(strip $($(THEOS_CURRENT_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
endif

_THEOS_INTERNAL_LDFLAGS += -lsubstrate

include $(THEOS_MAKE_PATH)/instance/library.mk

internal-tweak-all_:: internal-library-all_

internal-tweak-stage_:: internal-library-stage_
	$(ECHO_NOTHING)if [ -f $(THEOS_CURRENT_INSTANCE).plist ]; then cp $(THEOS_CURRENT_INSTANCE).plist "$(THEOS_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"; fi$(ECHO_END)

$(eval $(call __mod,instance/tweak.mk))
