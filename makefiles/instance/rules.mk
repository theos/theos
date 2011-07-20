.PHONY: before-$(THEOS_CURRENT_INSTANCE)-all after-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all \
	before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage

OBJ_FILES = $(strip $(patsubst %,%.o,$($(THEOS_CURRENT_INSTANCE)_FILES) $($(THEOS_CURRENT_INSTANCE)_OBJCC_FILES) $($(THEOS_CURRENT_INSTANCE)_LOGOS_FILES) $($(THEOS_CURRENT_INSTANCE)_OBJC_FILES) $($(THEOS_CURRENT_INSTANCE)_CC_FILES) $($(THEOS_CURRENT_INSTANCE)_C_FILES)))

_OBJC_FILE_COUNT = $(words $(filter %.m.o %.mm.o %.x.o %.xm.o %.xi.o %.xmi.o,$(OBJ_FILES)))
_OBJCC_FILE_COUNT = $(words $(filter %.mm.o %.xm.o %.xmi.o,$(OBJ_FILES)))

ifneq ($($(THEOS_CURRENT_INSTANCE)_SUBPROJECTS),)
SUBPROJECT_OBJ_FILES = $(foreach d, $($(THEOS_CURRENT_INSTANCE)_SUBPROJECTS), $(THEOS_BUILD_DIR)/$(d)/$(THEOS_OBJ_DIR_NAME)/$(THEOS_SUBPROJECT_PRODUCT))
#SUBPROJECT_OBJ_FILES = $(addsuffix /$(THEOS_OBJ_DIR_NAME)/$(THEOS_SUBPROJECT_PRODUCT), $(addprefix $(THEOS_BUILD_DIR)/,$($(THEOS_CURRENT_INSTANCE)_SUBPROJECTS)))
SUBPROJECT_LDFLAGS = $(shell sort $(foreach d, $($(THEOS_CURRENT_INSTANCE)_SUBPROJECTS), $(THEOS_BUILD_DIR)/$(d)/$(THEOS_OBJ_DIR_NAME)/ldflags) | uniq)
AUXILIARY_LDFLAGS += $(SUBPROJECT_LDFLAGS)
endif

OBJ_FILES_TO_LINK = $(strip $(addprefix $(THEOS_OBJ_DIR)/,$(OBJ_FILES)) $($(THEOS_CURRENT_INSTANCE)_OBJ_FILES) $(SUBPROJECT_OBJ_FILES))
_OBJ_DIR_STAMPS = $(sort $(foreach o,$(filter $(THEOS_OBJ_DIR)%,$(OBJ_FILES_TO_LINK)),$(dir $o).stamp))

ADDITIONAL_CPPFLAGS += $($(THEOS_CURRENT_INSTANCE)_CPPFLAGS)
ADDITIONAL_CFLAGS += $($(THEOS_CURRENT_INSTANCE)_CFLAGS)
ADDITIONAL_OBJCFLAGS += $($(THEOS_CURRENT_INSTANCE)_OBJCFLAGS)
ADDITIONAL_CCFLAGS += $($(THEOS_CURRENT_INSTANCE)_CCFLAGS)
ADDITIONAL_OBJCCFLAGS += $($(THEOS_CURRENT_INSTANCE)_OBJCCFLAGS)
ADDITIONAL_LDFLAGS += $($(THEOS_CURRENT_INSTANCE)_LDFLAGS)

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
AUXILIARY_LDFLAGS += $(foreach framework,$($(THEOS_CURRENT_INSTANCE)_FRAMEWORKS),-framework $(framework))

# Add all private frameworks from the type and instance, as well as -F for the private framework dir.
ifneq ($(words $($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS)$($(THEOS_CURRENT_INSTANCE)_PRIVATE_FRAMEWORKS)),0)
	AUXILIARY_OBJCFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
	AUXILIARY_LDFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
endif

AUXILIARY_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS),-framework $(framework))
AUXILIARY_LDFLAGS += $(foreach framework,$($(THEOS_CURRENT_INSTANCE)_PRIVATE_FRAMEWORKS),-framework $(framework))

before-$(THEOS_CURRENT_INSTANCE)-all::

after-$(THEOS_CURRENT_INSTANCE)-all::

internal-$(_THEOS_CURRENT_TYPE)-all:: before-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all_ after-$(THEOS_CURRENT_INSTANCE)-all

before-$(THEOS_CURRENT_INSTANCE)-stage::

after-$(THEOS_CURRENT_INSTANCE)-stage::

internal-$(_THEOS_CURRENT_TYPE)-stage:: before-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage_ after-$(THEOS_CURRENT_INSTANCE)-stage

define _THEOS_TEMPLATE_DEFAULT_LINKING_RULE
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
	$$(ECHO_LINKING)$$(TARGET_LD) $$(ALL_LDFLAGS) -o $$@ $$^$$(ECHO_END)
ifeq ($$(DEBUG),)
	$$(ECHO_STRIPPING)$$(TARGET_STRIP) $$(TARGET_STRIP_FLAGS) $$@$$(ECHO_END)
endif
ifneq ($$(_THEOS_CODESIGN_COMMANDLINE),)
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) $$@$$(ECHO_END)
endif
endef

define _THEOS_TEMPLATE_NOWARNING_LINKING_RULE
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
	$$(ECHO_LINKING)$$(TARGET_LD) $$(ALL_LDFLAGS) -o $$@ $$^$$(ECHO_END)
ifeq ($$(DEBUG),)
	$$(ECHO_STRIPPING)$$(TARGET_STRIP) $$(TARGET_STRIP_FLAGS) $$@$$(ECHO_END)
endif
ifneq ($$(_THEOS_CODESIGN_COMMANDLINE),)
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) $$@$$(ECHO_END)
endif
endef

$(eval $(call __mod,instance/rules.mk))
