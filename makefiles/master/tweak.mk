TWEAK_NAME := $(strip $(TWEAK_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(TWEAK_NAME:=.all.tweak.variables);

internal-package:: $(TWEAK_NAME:=.package.tweak.variables);

internal-install::
	ssh root@$(FW_DEVICE_IP) "killall -9 SpringBoard"

TWEAKS_WITH_SUBPROJECTS = $(strip $(foreach tweak,$(TWEAK_NAME),$(patsubst %,$(tweak),$($(tweak)_SUBPROJECTS))))
ifneq ($(TWEAKS_WITH_SUBPROJECTS),)
internal-clean:: $(TWEAKS_WITH_SUBPROJECTS:=.clean.tweak.subprojects)
endif

$(TWEAK_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.tweak.variables
