ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-framework-all_ internal-framework-package_

ifeq ($($(FW_INSTANCE)_FRAMEWORK_NAME),)
LOCAL_FRAMEWORK_NAME = $(FW_INSTANCE)
else
LOCAL_FRAMEWORK_NAME = $($(FW_INSTANCE)_FRAMEWORK_NAME)
endif

ALL_LDFLAGS += -dynamiclib -install_name $($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_FRAMEWORK_NAME).framework/$(FW_INSTANCE)

internal-framework-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(STRIP) -x $@$(ECHO_END)
endif   
	$(ECHO_SIGNING)CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@$(ECHO_END)


internal-framework-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_FRAMEWORK_NAME).framework
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_FRAMEWORK_NAME).framework
