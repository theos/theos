ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-library-all_ internal-library-stage_ internal-library-compile

LOCAL_INSTALL_PATH ?= $(strip $($(FW_INSTANCE)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = /usr/lib
endif

AUXILIARY_LDFLAGS += $(call TARGET_LDFLAGS_DYNAMICLIB,$(FW_INSTANCE)$(TARGET_LIB_EXT))
AUXILIARY_CFLAGS += $(TARGET_CFLAGS_DYNAMICLIB)

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-library-all_:: $(_OBJ_DIR_STAMPS) $(FW_OBJ_DIR)/$(FW_INSTANCE)$(TARGET_LIB_EXT)
else
internal-library-all_:: $(_OBJ_DIR_STAMPS)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-library-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-library-compile: $(FW_OBJ_DIR)/$(FW_INSTANCE)$(TARGET_LIB_EXT)
endif

$(eval $(call _FW_TEMPLATE_DEFAULT_LINKING_RULE,$(FW_INSTANCE)$(TARGET_LIB_EXT)))

internal-library-stage_::
	$(ECHO_NOTHING)mkdir -p "$(FW_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"$(ECHO_END)
	$(ECHO_NOTHING)cp $(FW_OBJ_DIR)/$(FW_INSTANCE)$(TARGET_LIB_EXT) "$(FW_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"$(ECHO_END)
