SUBPROJECT_NAME := $(strip $(SUBPROJECT_NAME))
ifneq ($(words $(SUBPROJECT_NAME)), 1)
SUBPROJECT_NAME := $(word 1, $(SUBPROJECT_NAME))
$(warning Only a single subproject can be built in any directory!)
$(warning Ignoring all subprojects and building only $(SUBPROJECT_NAME))
endif

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(SUBPROJECT_NAME:=.all.subproject.variables);

internal-stage:: $(SUBPROJECT_NAME:=.stage.subproject.variables);

SUBPROJECTS_WITH_SUBPROJECTS = $(strip $(foreach subproject,$(SUBPROJECT_NAME),$(patsubst %,$(subproject),$($(subproject)_SUBPROJECTS))))
ifneq ($(SUBPROJECTS_WITH_SUBPROJECTS),)
internal-clean:: $(SUBPROJECTS_WITH_SUBPROJECTS:=.clean.subproject.subprojects)
endif

$(SUBPROJECT_NAME):
	@$(MAKE) --no-print-directory --no-keep-going $@.all.subproject.variables
