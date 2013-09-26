BUNDLE_NAME := $(strip $(BUNDLE_NAME))

ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

internal-all:: $(BUNDLE_NAME:=.all.bundle.variables);

internal-stage:: $(BUNDLE_NAME:=.stage.bundle.variables);

BUNDLES_WITH_SUBPROJECTS = $(strip $(foreach bundle,$(BUNDLE_NAME),$(patsubst %,$(bundle),$(call __schema_var_all,$(bundle)_,SUBPROJECTS))))
ifneq ($(BUNDLES_WITH_SUBPROJECTS),)
internal-clean:: $(BUNDLES_WITH_SUBPROJECTS:=.clean.bundle.subprojects)
endif

$(BUNDLE_NAME):
	@$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.bundle.variables

$(eval $(call __mod,master/bundle.mk))
