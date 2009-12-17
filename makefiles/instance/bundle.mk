ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-bundle-all_

ALL_LDFLAGS += -dynamiclib

internal-bundle-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
	$(CXX) $(ALL_LDFLAGS) -o $@ $^
	$(STRIP) -x $@
	CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@

ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

internal-bundle-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_BUNDLE_NAME).bundle
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_BUNDLE_NAME).bundle
