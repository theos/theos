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

ifneq ($(strip $($(THEOS_CURRENT_INSTANCE)_BUNDLE_RESOURCE_DIRS) $($(THEOS_CURRENT_INSTANCE)_BUNDLE_RESOURCE_FILES)),)
_LOCAL_BUNDLE_INSTALL_PATH = $(or $($(THEOS_CURRENT_INSTANCE)_BUNDLE_INSTALL_PATH),/Library/Application Support/$(THEOS_CURRENT_INSTANCE))
_LOCAL_BUNDLE_NAME = $(or $($(THEOS_CURRENT_INSTANCE)_BUNDLE_NAME),$(THEOS_CURRENT_INSTANCE))
_LOCAL_BUNDLE_EXTENSION = $(or $($(THEOS_CURRENT_INSTANCE)_BUNDLE_EXTENSION),bundle)

_THEOS_SHARED_BUNDLE_BUILD_PATH = $(THEOS_OBJ_DIR)/$(_LOCAL_BUNDLE_NAME).$(_LOCAL_BUNDLE_EXTENSION)
_THEOS_SHARED_BUNDLE_STAGE_PATH = $(THEOS_STAGING_DIR)$(_LOCAL_BUNDLE_INSTALL_PATH)/$(_LOCAL_BUNDLE_NAME).$(_LOCAL_BUNDLE_EXTENSION)
include $(THEOS_MAKE_PATH)/instance/shared/bundle.mk

internal-tweak-all_:: shared-instance-bundle-all
internal-tweak-stage_:: shared-instance-bundle-stage
endif

internal-tweak-stage_:: $(_EXTRA_TARGET) internal-library-stage_
	$(ECHO_NOTHING)if [ -f $(THEOS_CURRENT_INSTANCE).plist ]; then cp $(THEOS_CURRENT_INSTANCE).plist "$(THEOS_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"; fi$(ECHO_END)

$(eval $(call __mod,instance/tweak.mk))
