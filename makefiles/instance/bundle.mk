ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-bundle-all_ internal-bundle-stage_ internal-bundle-compile

AUXILIARY_LDFLAGS += -dynamiclib

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-bundle-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)
else
internal-bundle-all_:: $(FW_OBJ_DIR)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-bundle-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-bundle-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE)
endif

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(TARGET_CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(TARGET_STRIP) -x $@$(ECHO_END)
endif   
	$(ECHO_SIGNING)$(FW_CODESIGN_COMMANDLINE) $@$(ECHO_END)


ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

ifeq ($($(FW_INSTANCE)_BUNDLE_EXTENSION),)
LOCAL_BUNDLE_EXTENSION = bundle
else
LOCAL_BUNDLE_EXTENSION = $($(FW_INSTANCE)_BUNDLE_EXTENSION)
endif

FW_SHARED_BUNDLE_RESOURCE_PATH = $(FW_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_BUNDLE_NAME).$(LOCAL_BUNDLE_EXTENSION)
include $(FW_MAKEDIR)/instance/shared/bundle.mk

internal-bundle-stage_:: shared-instance-bundle-stage
	$(ECHO_NOTHING)mkdir -p "$(FW_SHARED_BUNDLE_RESOURCE_PATH)"$(ECHO_END)
	$(ECHO_NOTHING)cp $(FW_OBJ_DIR)/$(FW_INSTANCE) "$(FW_SHARED_BUNDLE_RESOURCE_PATH)"$(ECHO_END)
