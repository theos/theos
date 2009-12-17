TOOL_NAME := $(strip $(TOOL_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(TOOL_NAME:=.all.tool.variables);

internal-package:: $(TOOL_NAME:=.package.tool.variables);

TOOLS_WITH_SUBPROJECTS = $(strip $(foreach tool,$(TOOL_NAME),$(patsubst %,$(tool),$($(tool)_SUBPROJECTS))))
ifneq ($(TOOLS_WITH_SUBPROJECTS),)
internal-clean:: $(TOOLS_WITH_SUBPROJECTS:=.clean.tool.subprojects)
endif

$(TOOL_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going $@.all.tool.variables
