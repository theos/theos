ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

.PHONY: internal-null-all_ internal-null-stage_

internal-null-all_::

internal-null-stage_::
