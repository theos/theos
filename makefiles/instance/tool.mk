ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tool-all_ internal-tool-stage_ internal-tool-compile

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-tool-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)
else
internal-tool-all_:: $(FW_OBJ_DIR)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-tool-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-tool-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE)
endif

$(FW_OBJ_DIR)/$(FW_INSTANCE): $(OBJ_FILES_TO_LINK)
ifeq ($(DEBUG),)
	$(ECHO_LINKING_WITH_STRIP)$(TARGET_CXX) $(ALL_LDFLAGS) -Wl,-single_module,-x -o $@ $^$(ECHO_END)
else
	$(ECHO_LINKING)$(TARGET_CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
endif   
	$(ECHO_SIGNING)$(FW_CODESIGN_COMMANDLINE) $@$(ECHO_END)

LOCAL_INSTALL_PATH = $(strip $($(FW_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = $($(FW_INSTANCE)_PACKAGE_TARGET_DIR)
	ifeq ($(LOCAL_INSTALL_PATH),)
		LOCAL_INSTALL_PATH = /usr/bin
	endif
endif

internal-tool-stage_::
	$(ECHO_NOTHING)mkdir -p "$(FW_STAGING_DIR)$(LOCAL_INSTALL_PATH)"$(ECHO_END)
	$(ECHO_NOTHING)cp $(FW_OBJ_DIR)/$(FW_INSTANCE) "$(FW_STAGING_DIR)$(LOCAL_INSTALL_PATH)"$(ECHO_END)
