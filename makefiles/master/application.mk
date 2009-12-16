APPLICATION_NAME := $(strip $(APPLICATION_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(APPLICATION_NAME:=.all.application.variables);

internal-stage:: $(APPLICATION_NAME:=.stage.application.variables);

internal-clean::

$(APPLICATION_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.application.variables
