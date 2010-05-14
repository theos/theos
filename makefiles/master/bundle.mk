BUNDLE_NAME := $(strip $(BUNDLE_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(BUNDLE_NAME:=.all.bundle.variables);

internal-stage:: $(BUNDLE_NAME:=.stage.bundle.variables);

BUNDLES_WITH_SUBPROJECTS = $(strip $(foreach bundle,$(BUNDLE_NAME),$(patsubst %,$(bundle),$($(bundle)_SUBPROJECTS))))
ifneq ($(BUNDLES_WITH_SUBPROJECTS),)
internal-clean:: $(BUNDLES_WITH_SUBPROJECTS:=.clean.bundle.subprojects)
endif

$(BUNDLE_NAME):
	@$(MAKE) --no-print-directory --no-keep-going $@.all.bundle.variables
