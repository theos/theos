ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-tool-all_ internal-tool-package_ internal-tool-compile

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
	$(ECHO_LINKING)$(TARGET_CXX) $(ALL_LDFLAGS) -o $@ $^$(ECHO_END)
ifeq ($(DEBUG),)
	$(ECHO_STRIPPING)$(TARGET_STRIP) -x $@$(ECHO_END)
endif   
	$(ECHO_SIGNING)CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(TARGET_CODESIGN) -S $@$(ECHO_END)

LOCAL_INSTALL_PATH = $(strip $($(FW_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = $($(FW_INSTANCE)_PACKAGE_TARGET_DIR)
	ifeq ($(LOCAL_INSTALL_PATH),)
		LOCAL_INSTALL_PATH = /usr/bin
	endif
endif

internal-tool-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)$(LOCAL_INSTALL_PATH)
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)$(LOCAL_INSTALL_PATH)
