ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-library-all_ internal-library-package_

LOCAL_INSTALL_PATH = $(strip $($(FW_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = /usr/lib
endif

AUXILIARY_LDFLAGS += -dynamiclib -install_name $(LOCAL_INSTALL_PATH)/$(FW_INSTANCE).dylib

internal-library-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib

$(FW_OBJ_DIR)/$(FW_INSTANCE).dylib: $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(STRIP) -x $@$(ECHO_END)
endif   
	$(ECHO_SIGNING)CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@$(ECHO_END)


internal-library-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)$(LOCAL_INSTALL_PATH)/
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib $(FW_PACKAGE_STAGING_DIR)$(LOCAL_INSTALL_PATH)/
