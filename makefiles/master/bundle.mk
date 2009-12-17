BUNDLE_NAME := $(strip $(BUNDLE_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(BUNDLE_NAME:=.all.bundle.variables);

internal-package:: $(BUNDLE_NAME:=.package.bundle.variables);

BUNDLES_WITH_SUBPROJECTS = $(strip $(foreach bundle,$(BUNDLE_NAME),$(patsubst %,$(bundle),$($(bundle)_SUBPROJECTS))))
ifneq ($(BUNDLES_WITH_SUBPROJECTS),)
internal-clean:: $(BUNDLES_WITH_SUBPROJECTS:=.clean.bundle.subprojects)
endif

$(BUNDLE_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.bundle.variables
