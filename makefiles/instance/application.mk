ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-application-all_ internal-application-stage_ internal-application-compile

AUXILIARY_LDFLAGS += -framework UIKit

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-application-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)$(TARGET_EXE_EXT)
else
internal-application-all_:: $(FW_OBJ_DIR)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-application-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-application-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE)$(TARGET_EXE_EXT)
endif

$(eval $(call _FW_TEMPLATE_DEFAULT_LINKING_RULE,$(FW_INSTANCE)$(TARGET_EXE_EXT)))

ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

FW_SHARED_BUNDLE_RESOURCE_PATH = $(FW_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app
include $(FW_MAKEDIR)/instance/shared/bundle.mk

internal-application-stage_:: shared-instance-bundle-stage
	$(ECHO_NOTHING)mkdir -p "$(FW_SHARED_BUNDLE_RESOURCE_PATH)"$(ECHO_END)
	$(ECHO_NOTHING)cp $(FW_OBJ_DIR)/$(FW_INSTANCE)$(TARGET_EXE_EXT) "$(FW_SHARED_BUNDLE_RESOURCE_PATH)"$(ECHO_END)
