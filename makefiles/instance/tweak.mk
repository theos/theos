ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tweak-all_ internal-tweak-package_ internal-tweak-compile

AUXILIARY_LDFLAGS += -dynamiclib -lsubstrate

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-tweak-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib
else
internal-tweak-all_:: $(FW_OBJ_DIR)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-tweak-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-tweak-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib
endif

$(FW_OBJ_DIR)/$(FW_INSTANCE).dylib: $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(TARGET_CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(TARGET_STRIP) -x $@$(ECHO_END)
endif   
	$(ECHO_SIGNING)$(FW_CODESIGN_COMMANDLINE) $@$(ECHO_END)


internal-tweak-package_::
	$(ECHO_NOTHING)mkdir -p "$(FW_PACKAGE_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries"$(ECHO_END)
	$(ECHO_NOTHING)cp $(FW_OBJ_DIR)/$(FW_INSTANCE).dylib "$(FW_PACKAGE_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries"$(ECHO_END)
