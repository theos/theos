LIBRARY_NAME := $(strip $(LIBRARY_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(LIBRARY_NAME:=.all.library.variables);

internal-stage:: $(LIBRARY_NAME:=.stage.library.variables);

LIBRARYS_WITH_SUBPROJECTS = $(strip $(foreach library,$(LIBRARY_NAME),$(patsubst %,$(library),$($(library)_SUBPROJECTS))))
ifneq ($(LIBRARYS_WITH_SUBPROJECTS),)
internal-clean:: $(LIBRARYS_WITH_SUBPROJECTS:=.clean.library.subprojects)
endif

$(LIBRARY_NAME):
	@$(MAKE) --no-print-directory --no-keep-going $@.all.library.variables
