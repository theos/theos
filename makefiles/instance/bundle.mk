ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-bundle-all_ internal-bundle-package_ internal-bundle-compile

AUXILIARY_LDFLAGS += -dynamiclib

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-bundle-all_:: $(FW_OBJ_DIR) $(FW_OBJ_DIR)/$(FW_INSTANCE)
else
internal-bundle-all_:: $(FW_OBJ_DIR)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-bundle-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-bundle-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE)
endif

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

ifeq ($($(FW_INSTANCE)_BUNDLE_EXTENSION),)
LOCAL_BUNDLE_EXTENSION = bundle
else
LOCAL_BUNDLE_EXTENSION = $($(FW_INSTANCE)_BUNDLE_EXTENSION)
endif

internal-bundle-package_::
	mkdir -p $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_BUNDLE_NAME).$(LOCAL_BUNDLE_EXTENSION)
	cp $(FW_OBJ_DIR)/$(FW_INSTANCE) $(FW_PACKAGE_STAGING_DIR)$($(FW_INSTANCE)_INSTALL_PATH)/$(LOCAL_BUNDLE_NAME).$(LOCAL_BUNDLE_EXTENSION)
