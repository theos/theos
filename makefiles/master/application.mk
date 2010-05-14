APPLICATION_NAME := $(strip $(APPLICATION_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(APPLICATION_NAME:=.all.application.variables);

internal-stage:: $(APPLICATION_NAME:=.stage.application.variables);

# Maybe, disabled for further discussion
# ssh mobile@$(FW_DEVICE_IP) "uicache"
internal-after-install::

APPLICATIONS_WITH_SUBPROJECTS = $(strip $(foreach application,$(APPLICATION_NAME),$(patsubst %,$(application),$($(application)_SUBPROJECTS))))
ifneq ($(APPLICATIONS_WITH_SUBPROJECTS),)
internal-clean:: $(APPLICATIONS_WITH_SUBPROJECTS:=.clean.application.subprojects)
endif

$(APPLICATION_NAME):
	@$(MAKE) --no-print-directory --no-keep-going $@.all.application.variables
