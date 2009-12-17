NULL_NAME := $(strip $(NULL_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(NULL_NAME:=.all.null.variables);

internal-package:: $(NULL_NAME:=.package.null.variables);

NULLS_WITH_SUBPROJECTS = $(strip $(foreach null,$(NULL_NAME),$(patsubst %,$(null),$($(null)_SUBPROJECTS))))
ifneq ($(NULLS_WITH_SUBPROJECTS),)
internal-clean:: $(NULLS_WITH_SUBPROJECTS:=.clean.null.subprojects)
endif

$(NULL_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.null.variables
