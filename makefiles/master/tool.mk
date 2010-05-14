TOOL_NAME := $(strip $(TOOL_NAME))

ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

internal-all:: $(TOOL_NAME:=.all.tool.variables);

internal-stage:: $(TOOL_NAME:=.stage.tool.variables);

TOOLS_WITH_SUBPROJECTS = $(strip $(foreach tool,$(TOOL_NAME),$(patsubst %,$(tool),$($(tool)_SUBPROJECTS))))
ifneq ($(TOOLS_WITH_SUBPROJECTS),)
internal-clean:: $(TOOLS_WITH_SUBPROJECTS:=.clean.tool.subprojects)
endif

$(TOOL_NAME):
	@$(MAKE) --no-print-directory --no-keep-going $@.all.tool.variables
