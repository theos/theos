ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

.PHONY: internal-subproject-all_ internal-subproject-stage_ internal-subproject-compile

ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING), no)
internal-subproject-all_:: $(_OBJ_DIR_STAMPS) $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE).$(THEOS_SUBPROJECT_PRODUCT)
else
internal-subproject-all_:: $(_OBJ_DIR_STAMPS)
	$(ECHO_NOTHING)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going \
		internal-subproject-compile \
		_THEOS_CURRENT_TYPE=$(_THEOS_CURRENT_TYPE) THEOS_CURRENT_INSTANCE=$(THEOS_CURRENT_INSTANCE) _THEOS_CURRENT_OPERATION=compile \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" _THEOS_MAKE_PARALLEL=yes$(ECHO_END)

internal-subproject-compile: $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE).$(THEOS_SUBPROJECT_PRODUCT)
endif

$(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE).$(THEOS_SUBPROJECT_PRODUCT): $(OBJ_FILES_TO_LINK)
	$(ECHO_LINKING)$(TARGET_LD) -nostdlib -r -d $(ADDITIONAL_LDFLAGS) $(_THEOS_TARGET_LDFLAGS) $(LDFLAGS) -o $@ $^$(ECHO_END)
	@echo "$(_THEOS_INTERNAL_LDFLAGS)" > $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE).ldflags

$(eval $(call __mod,instance/subproject.mk))
