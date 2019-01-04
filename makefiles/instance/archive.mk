ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

.PHONY: internal-archive-all_ internal-archive-stage_ internal-archive-compile

# This is needed to let compile a library and archive with the same name without warnings
NAME = $(THEOS_CURRENT_INSTANCE:.a=)
LOCAL_INSTALL_PATH ?= $(strip $($(NAME)_INSTALL_PATH))
ifeq ($(LOCAL_INSTALL_PATH),)
	LOCAL_INSTALL_PATH = /usr/lib
endif

_LOCAL_ARCHIVE_EXTENSION = $(or $($(NAME)_ARCHIVE_EXTENSION),.a)
ifeq ($(_LOCAL_ARCHIVE_EXTENSION),-)
	_LOCAL_ARCHIVE_EXTENSION =
endif

ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING), no)
internal-archive-all_:: $(_OBJ_DIR_STAMPS) $(THEOS_OBJ_DIR)/$(NAME)$(_LOCAL_ARCHIVE_EXTENSION)
else
internal-archive-all_:: $(_OBJ_DIR_STAMPS)
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) \
		internal-archive-compile \
		_THEOS_CURRENT_TYPE=$(_THEOS_CURRENT_TYPE) THEOS_CURRENT_INSTANCE=$(THEOS_CURRENT_INSTANCE) _THEOS_CURRENT_OPERATION=compile \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" _THEOS_MAKE_PARALLEL=yes

internal-archive-compile: $(THEOS_OBJ_DIR)/$(NAME)$(_LOCAL_ARCHIVE_EXTENSION)
endif

$(eval $(call _THEOS_TEMPLATE_DEFAULT_ARCHIVE_RULE,$(NAME)$(_LOCAL_ARCHIVE_EXTENSION)))

ifneq ($($(NAME)_INSTALL),0)
internal-archive-stage_::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"$(ECHO_END)
	$(ECHO_NOTHING)cp $(THEOS_OBJ_DIR)/$(NAME)$(_LOCAL_ARCHIVE_EXTENSION) "$(THEOS_STAGING_DIR)$(LOCAL_INSTALL_PATH)/"$(ECHO_END)
endif

$(eval $(call __mod,instance/archive.mk))
