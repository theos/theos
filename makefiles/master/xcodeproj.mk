XCODEPROJ_NAME := $(strip $(XCODEPROJ_NAME))

ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

internal-all:: $(XCODEPROJ_NAME:=.all.xcodeproj.variables);

internal-stage:: $(XCODEPROJ_NAME:=.stage.xcodeproj.variables);

internal-clean:: $(XCODEPROJ_NAME:=.clean.xcodeproj.variables);

XCODEPROJ_WITH_SUBPROJECTS = $(strip $(foreach xcodeproj,$(XCODEPROJ_NAME),$(patsubst %,$(xcodeproj),$(call __schema_var_all,$(xcodeproj)_,SUBPROJECTS))))
ifneq ($(XCODEPROJ_WITH_SUBPROJECTS),)
internal-clean:: $(XCODEPROJ_WITH_SUBPROJECTS:=.clean.xcodeproj.subprojects)
endif

$(XCODEPROJ_NAME):
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) $@.all.xcodeproj.variables

$(eval $(call __mod,master/xcodeproj.mk))
