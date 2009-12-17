ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tool-all_

internal-tool-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
	$(CXX) $(ALL_LDFLAGS) -o $@ $^
	$(STRIP) -x $@
	CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@

internal-tool-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_PACKAGE_TARGET_DIR)
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_PACKAGE_TARGET_DIR)
