ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-subproject-all_ internal-subproject-stage_ internal-subproject-compile

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
internal-subproject-all_:: $(_OBJ_DIR_STAMPS) $(FW_OBJ_DIR)/$(FW_SUBPROJECT_PRODUCT)
else
internal-subproject-all_:: $(_OBJ_DIR_STAMPS)
	$(ECHO_NOTHING)$(MAKE) --no-print-directory --no-keep-going \
		internal-subproject-compile \
		FW_TYPE=$(FW_TYPE) FW_INSTANCE=$(FW_INSTANCE) FW_OPERATION=compile \
		FW_BUILD_DIR="$(FW_BUILD_DIR)" _FW_MAKE_PARALLEL=yes$(ECHO_END)

internal-subproject-compile: $(FW_OBJ_DIR)/$(FW_SUBPROJECT_PRODUCT)
endif

$(FW_OBJ_DIR)/$(FW_SUBPROJECT_PRODUCT): $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(TARGET_CXX) -nostdlib -r -d $(ADDITIONAL_LDFLAGS) $(TARGET_LDFLAGS) $(LDFLAGS) -o $@ $^$(ECHO_END)
	@echo "$(AUXILIARY_LDFLAGS)" > $(FW_OBJ_DIR)/ldflags
