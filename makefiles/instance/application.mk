ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-application-all_

ALL_LDFLAGS += -framework UIKit

internal-application-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
	$(CXX) $(ALL_LDFLAGS) -o $@ $^
	$(STRIP) -x $@
	CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@

ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

internal-application-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)/Application/$(LOCAL_BUNDLE_NAME).app
