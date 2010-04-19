ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-application-all_ internal-application-stage_ internal-application-compile

AUXILIARY_LDFLAGS += -framework UIKit

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-application-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)
else
internal-application-all_:: $(FW_OBJ_DIR)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-application-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-application-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE)
endif

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
ifeq ($(DEBUG),)
	$(ECHO_LINKING_WITH_STRIP)$(TARGET_CXX) $(ALL_LDFLAGS) -Wl,-single_module,-x -o $@ $^$(ECHO_END)
else
	$(ECHO_LINKING)$(TARGET_CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
endif   
	$(ECHO_SIGNING)$(FW_CODESIGN_COMMANDLINE) $@$(ECHO_END)

ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

internal-application-stage_::
	$(ECHO_NOTHING)mkdir -p "$(FW_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app"$(ECHO_END)
	$(ECHO_NOTHING)cp $(FW_OBJ_DIR)/$(FW_INSTANCE) "$(FW_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app"$(ECHO_END)
