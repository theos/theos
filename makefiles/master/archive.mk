ARCHIVE_NAME := $(strip $(ARCHIVE_NAME))

ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

internal-all:: $(ARCHIVE_NAME:=.all.archive.variables);

internal-stage:: $(ARCHIVE_NAME:=.stage.archive.variables);

ARCHIVES_WITH_SUBPROJECTS = $(strip $(foreach archive,$(ARCHIVE_NAME),$(patsubst %,$(archive),$(call __schema_var_all,$(archive)_,SUBPROJECTS))))
ifneq ($(ARCHIVES_WITH_SUBPROJECTS),)
internal-clean:: $(ARCHIVES_WITH_SUBPROJECTS:=.clean.archive.subprojects)
endif

$(ARCHIVE_NAME).a:
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) $@.all.archive.variables

$(eval $(call __mod,master/archive.mk))
