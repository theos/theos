.PHONY: before-$(THEOS_CURRENT_INSTANCE)-all after-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all \
	before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage

ifneq ($(_THEOS_TARGET_CALCULATED),1)
__TARGET_MAKEFILE := $(shell $(THEOS_BIN_PATH)/target.pl "$(target)" "$(call __schema_var_last,,TARGET)" "$(_THEOS_PLATFORM_DEFAULT_TARGET)")
-include $(__TARGET_MAKEFILE)
$(shell rm -f $(__TARGET_MAKEFILE) > /dev/null 2>&1)
export _THEOS_TARGET := $(__THEOS_TARGET_ARG_0)
ifeq ($(_THEOS_TARGET),)
$(error You did not specify a target, and the "$(THEOS_PLATFORM_NAME)" platform does not define a default target)
endif
export _THEOS_TARGET_CALCULATED := 1
endif

-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_PLATFORM_ARCH)/$(_THEOS_TARGET).mk
-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_PLATFORM)/$(_THEOS_TARGET).mk
-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_TARGET).mk
$(eval $(call __mod,targets/$(_THEOS_PLATFORM_ARCH)/$(_THEOS_TARGET).mk))
$(eval $(call __mod,targets/$(_THEOS_PLATFORM)/$(_THEOS_TARGET).mk))
$(eval $(call __mod,targets/$(_THEOS_TARGET).mk))

ifneq ($(_THEOS_TARGET_LOADED),1)
$(error The "$(_THEOS_TARGET)" target is not supported on the "$(THEOS_PLATFORM_NAME)" platform)
endif

_THEOS_TARGET_NAME_DEFINE := $(shell echo "$(THEOS_TARGET_NAME)" | tr 'a-z' 'A-Z')

export TARGET_CC TARGET_CXX TARGET_LD TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS

THEOS_TARGET_INCLUDE_PATH := $(THEOS_INCLUDE_PATH)/$(THEOS_TARGET_NAME)
THEOS_TARGET_LIBRARY_PATH := $(THEOS_LIBRARY_PATH)/$(THEOS_TARGET_NAME)
_THEOS_TARGET_HAS_INCLUDE_PATH := $(shell [ -d "$(THEOS_TARGET_INCLUDE_PATH)" ] && echo 1)
_THEOS_TARGET_HAS_LIBRARY_PATH := $(shell [ -d "$(THEOS_TARGET_LIBRARY_PATH)" ] && echo 1)

# ObjC/++ stuff is not here, it's in instance/rules.mk and only added if there are OBJC/OBJCC objects.
INTERNAL_LDFLAGS = $(if $(_THEOS_TARGET_HAS_LIBRARY_PATH),-L$(THEOS_TARGET_LIBRARY_PATH) )-L$(THEOS_LIBRARY_PATH)
INTERNAL_CFLAGS += -DTARGET_$(_THEOS_TARGET_NAME_DEFINE)=1 $(OPTFLAG) $(if $(_THEOS_TARGET_HAS_INCLUDE_PATH),-I$(THEOS_TARGET_INCLUDE_PATH) )-I$(THEOS_INCLUDE_PATH) -include $(THEOS)/Prefix.pch -Wall
INTERNAL_CFLAGS += $(SHARED_CFLAGS)

__ALL_FILES = $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FILES) $($(THEOS_CURRENT_INSTANCE)_OBJCC_FILES) $($(THEOS_CURRENT_INSTANCE)_LOGOS_FILES) $($(THEOS_CURRENT_INSTANCE)_OBJC_FILES) $($(THEOS_CURRENT_INSTANCE)_CC_FILES) $($(THEOS_CURRENT_INSTANCE)_C_FILES)
__ON_FILES = $(filter-out -%,$(__ALL_FILES))
__OFF_FILES = $(patsubst -%,%,$(filter -%,$(__ALL_FILES)))
_FILES = $(strip $(filter-out $(__OFF_FILES),$(__ON_FILES)))
OBJ_FILES = $(strip $(patsubst %,%.o,$(_FILES)))

_OBJC_FILE_COUNT = $(words $(filter %.m %.mm %.x %.xm %.xi %.xmi,$(_FILES)))
_OBJCC_FILE_COUNT = $(words $(filter %.mm %.xm %.xmi,$(_FILES)))

_SUBPROJECTS = $(strip $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,SUBPROJECTS))
ifneq ($(_SUBPROJECTS),)
SUBPROJECT_OBJ_FILES = $(foreach d, $(_SUBPROJECTS), $(THEOS_BUILD_DIR)/$(firstword $(subst :, ,$(d)))/$(THEOS_OBJ_DIR_NAME)/$(or $(word 2,$(subst :, ,$(d))),*).$(THEOS_SUBPROJECT_PRODUCT))
#SUBPROJECT_OBJ_FILES = $(addsuffix /$(THEOS_OBJ_DIR_NAME)/$(THEOS_SUBPROJECT_PRODUCT), $(addprefix $(THEOS_BUILD_DIR)/,$($(THEOS_CURRENT_INSTANCE)_SUBPROJECTS)))
SUBPROJECT_LDFLAGS = $(shell sort $(foreach d,$(_SUBPROJECTS),$(THEOS_BUILD_DIR)/$(firstword $(subst :, ,$(d)))/$(THEOS_OBJ_DIR_NAME)/$(or $(word 2,$(subst :, ,$(d))),*).ldflags) | uniq)
AUXILIARY_LDFLAGS += $(SUBPROJECT_LDFLAGS)
endif

OBJ_FILES_TO_LINK = $(strip $(addprefix $(THEOS_OBJ_DIR)/,$(OBJ_FILES)) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJ_FILES) $(SUBPROJECT_OBJ_FILES))
_OBJ_DIR_STAMPS = $(sort $(foreach o,$(filter $(THEOS_OBJ_DIR)%,$(OBJ_FILES_TO_LINK)),$(dir $o).stamp))

ADDITIONAL_CPPFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CPPFLAGS)
ADDITIONAL_CFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CFLAGS)
ADDITIONAL_OBJCFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCFLAGS)
ADDITIONAL_CCFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CCFLAGS)
ADDITIONAL_OBJCCFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCCFLAGS)
ADDITIONAL_LOGOSFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LOGOSFLAGS)
ADDITIONAL_LDFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LDFLAGS)

# If we have any Objective-C objects, link Foundation and libobjc.
ifneq ($(_OBJC_FILE_COUNT),0)
	AUXILIARY_LDFLAGS += -lobjc -framework Foundation -framework CoreFoundation
endif

# In addition, if we have any Objective-C++, add the ObjC++ linker flags.
ifneq ($(_OBJCC_FILE_COUNT),0)
	AUXILIARY_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
endif

# Add all frameworks from the type and instance.
AUXILIARY_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_FRAMEWORKS),-framework $(framework))
AUXILIARY_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FRAMEWORKS),-framework $(framework))

# Add all libraries from the type and instance.
AUXILIARY_LDFLAGS += $(foreach library,$($(_THEOS_CURRENT_TYPE)_LIBRARIES),-l$(library))
AUXILIARY_LDFLAGS += $(foreach library,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LIBRARIES),-l$(library))

# Add all private frameworks from the type and instance, as well as -F for the private framework dir.
ifneq ($(words $($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS)$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS)),0)
	AUXILIARY_OBJCFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
	AUXILIARY_LDFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
endif

AUXILIARY_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS),-framework $(framework))
AUXILIARY_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS),-framework $(framework))

before-$(THEOS_CURRENT_INSTANCE)-all::

after-$(THEOS_CURRENT_INSTANCE)-all::

internal-$(_THEOS_CURRENT_TYPE)-all:: before-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all_ after-$(THEOS_CURRENT_INSTANCE)-all

before-$(THEOS_CURRENT_INSTANCE)-stage::

after-$(THEOS_CURRENT_INSTANCE)-stage::

internal-$(_THEOS_CURRENT_TYPE)-stage:: before-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage_ after-$(THEOS_CURRENT_INSTANCE)-stage

define _THEOS_TEMPLATE_DEFAULT_LINKING_RULE
ifneq ($$(_THEOS_CODESIGN_COMMANDLINE),)
.INTERMEDIATE: $$(THEOS_OBJ_DIR)/$(1).unsigned
$$(THEOS_OBJ_DIR)/$(1): $$(THEOS_OBJ_DIR)/$(1).unsigned
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) "$$<"; mv "$$<" "$$@"$$(ECHO_END)
$$(THEOS_OBJ_DIR)/$(1).unsigned: $$(OBJ_FILES_TO_LINK)
else
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
endif
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
	$$(ECHO_LINKING)$$(TARGET_LD) $$(ALL_LDFLAGS) -o "$$@" $$^$$(ECHO_END)
ifeq ($$(DEBUG),)
	$$(ECHO_STRIPPING)$$(TARGET_STRIP) $$(TARGET_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endef

$(eval $(call __mod,instance/rules.mk))
