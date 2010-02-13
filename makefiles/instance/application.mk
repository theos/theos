ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-application-all_ internal-application-package_ internal-application-compile

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
	$(ECHO_LINKING)$(TARGET_CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(TARGET_STRIP) -x $@$(ECHO_END)
endif
	$(ECHO_SIGNING)CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(TARGET_CODESIGN) -S $@$(ECHO_END)

ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

internal-application-package_::
	mkdir -p "$(FW_PACKAGE_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app"
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) "$(FW_PACKAGE_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app"
