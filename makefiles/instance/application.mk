ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-application-all_ internal-application-package_

ALL_LDFLAGS += -framework UIKit

internal-application-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(STRIP) -x $@$(ECHO_END)
endif
	$(ECHO_SIGNING)CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@$(ECHO_END)

ifeq ($($(FW_INSTANCE)_BUNDLE_NAME),)
LOCAL_BUNDLE_NAME = $(FW_INSTANCE)
else
LOCAL_BUNDLE_NAME = $($(FW_INSTANCE)_BUNDLE_NAME)
endif

internal-application-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)/Applications/$(LOCAL_BUNDLE_NAME).app
