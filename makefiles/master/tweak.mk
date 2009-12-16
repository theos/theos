TWEAK_NAME := $(strip $(TWEAK_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(TWEAK_NAME:=.all.tweak.variables);

internal-stage:: $(TWEAK_NAME:=.stage.tweak.variables);

internal-clean::

$(TWEAK_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.tweak.variables
