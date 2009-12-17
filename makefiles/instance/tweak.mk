ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tweak-all_

ALL_LDFLAGS += -dynamiclib -lsubstrate

internal-tweak-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib

$(FW_OBJ_DIR)/$(FW_INSTANCE).dylib: $(OBJ_FILES_TO_LINK)
	$(CXX) $(ALL_LDFLAGS) -o $@ $^
	$(STRIP) -x $@
	CODESIGN_ALLOCATE=$(CODESIGN_ALLOCATE) ldid -S $@

internal-tweak-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib $(FW_PACKAGE_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries
