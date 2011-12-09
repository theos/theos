TWEAK_NAME := $(strip $(TWEAK_NAME))

ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

before-all::
	@[ -f "$(THEOS_LIBRARY_PATH)/libsubstrate.dylib" ] || bootstrap.sh substrate

internal-all:: $(TWEAK_NAME:=.all.tweak.variables);

internal-stage:: $(TWEAK_NAME:=.stage.tweak.variables);

internal-after-install::
	install.exec "killall -9 SpringBoard"

TWEAKS_WITH_SUBPROJECTS = $(strip $(foreach tweak,$(TWEAK_NAME),$(patsubst %,$(tweak),$(call __schema_var_all,$(tweak)_,SUBPROJECTS))))
ifneq ($(TWEAKS_WITH_SUBPROJECTS),)
internal-clean:: $(TWEAKS_WITH_SUBPROJECTS:=.clean.tweak.subprojects)
endif

$(TWEAK_NAME):
	@$(MAKE) --no-print-directory --no-keep-going $@.all.tweak.variables

$(eval $(call __mod,master/tweak.mk))
