APPLICATION_NAME := $(strip $(APPLICATION_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(APPLICATION_NAME:=.all.application.variables);

internal-package:: $(APPLICATION_NAME:=.package.application.variables);

internal-install::
	ssh mobile@$(FW_DEVICE_IP) "uicache"

APPLICATIONS_WITH_SUBPROJECTS = $(strip $(foreach application,$(APPLICATION_NAME),$(patsubst %,$(application),$($(application)_SUBPROJECTS))))
ifneq ($(APPLICATIONS_WITH_SUBPROJECTS),)
internal-clean:: $(APPLICATIONS_WITH_SUBPROJECTS:=.clean.application.subprojects)
endif

$(APPLICATION_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.application.variables
