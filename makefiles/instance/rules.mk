.PHONY: before-$(FW_INSTANCE)-all after-$(FW_INSTANCE)-all internal-$(FW_TYPE)-all \
	before-$(FW_INSTANCE)-stage after-$(FW_INSTANCE)-stage internal-$(FW_TYPE)-stage

OBJ_FILES = $(strip $(patsubst %,%.o,$($(FW_INSTANCE)_FILES) $($(FW_INSTANCE)_OBJCC_FILES) $($(FW_INSTANCE)_LOGOS_FILES) $($(FW_INSTANCE)_OBJC_FILES) $($(FW_INSTANCE)_CC_FILES) $($(FW_INSTANCE)_C_FILES)))

_OBJC_FILE_COUNT = $(words $(filter %.m.o %.mm.o %.xm.o,$(OBJ_FILES)))
_OBJCC_FILE_COUNT = $(words $(filter %.mm.o %.xm.o,$(OBJ_FILES)))

ifneq ($($(FW_INSTANCE)_SUBPROJECTS),)
SUBPROJECT_OBJ_FILES = $(foreach d, $($(FW_INSTANCE)_SUBPROJECTS), $(FW_BUILD_DIR)/$(d)/$(FW_OBJ_DIR_NAME)/$(FW_SUBPROJECT_PRODUCT))
#SUBPROJECT_OBJ_FILES = $(addsuffix /$(FW_OBJ_DIR_NAME)/$(FW_SUBPROJECT_PRODUCT), $(addprefix $(FW_BUILD_DIR)/,$($(FW_INSTANCE)_SUBPROJECTS)))
SUBPROJECT_LDFLAGS = $(shell sort $(foreach d, $($(FW_INSTANCE)_SUBPROJECTS), $(FW_BUILD_DIR)/$(d)/$(FW_OBJ_DIR_NAME)/ldflags) | uniq)
AUXILIARY_LDFLAGS += $(SUBPROJECT_LDFLAGS)
endif

OBJ_FILES_TO_LINK = $(strip $(addprefix $(FW_OBJ_DIR)/,$(OBJ_FILES)) $($(FW_INSTANCE)_OBJ_FILES) $(SUBPROJECT_OBJ_FILES))
_OBJ_DIR_STAMPS = $(sort $(foreach o,$(filter $(FW_OBJ_DIR)%,$(OBJ_FILES_TO_LINK)),$(dir $o).stamp))

ADDITIONAL_CPPFLAGS += $($(FW_INSTANCE)_CPPFLAGS)
ADDITIONAL_CFLAGS += $($(FW_INSTANCE)_CFLAGS)
ADDITIONAL_OBJCFLAGS += $($(FW_INSTANCE)_OBJCFLAGS)
ADDITIONAL_CCFLAGS += $($(FW_INSTANCE)_CCFLAGS)
ADDITIONAL_OBJCCFLAGS += $($(FW_INSTANCE)_OBJCCFLAGS)
ADDITIONAL_LDFLAGS += $($(FW_INSTANCE)_LDFLAGS)

# If we have any Objective-C objects, link Foundation and libobjc.
ifneq ($(_OBJC_FILE_COUNT),0)
	AUXILIARY_LDFLAGS += -lobjc -framework Foundation -framework CoreFoundation
endif

# In addition, if we have any Objective-C++, add the ObjC++ linker flags.
ifneq ($(_OBJCC_FILE_COUNT),0)
	AUXILIARY_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
endif

# Add all frameworks from the type and instance.
AUXILIARY_LDFLAGS += $(foreach framework,$($(FW_TYPE)_FRAMEWORKS),-framework $(framework))
AUXILIARY_LDFLAGS += $(foreach framework,$($(FW_INSTANCE)_FRAMEWORKS),-framework $(framework))

# Add all private frameworks from the type and instance, as well as -F for the private framework dir.
ifneq ($(words $($(FW_TYPE)_PRIVATE_FRAMEWORKS)$($(FW_INSTANCE)_PRIVATE_FRAMEWORKS)),0)
	AUXILIARY_OBJCFLAGS += -F/System/Library/PrivateFrameworks
	AUXILIARY_LDFLAGS += -F/System/Library/PrivateFrameworks
endif

AUXILIARY_LDFLAGS += $(foreach framework,$($(FW_TYPE)_PRIVATE_FRAMEWORKS),-framework $(framework))
AUXILIARY_LDFLAGS += $(foreach framework,$($(FW_INSTANCE)_PRIVATE_FRAMEWORKS),-framework $(framework))

before-$(FW_INSTANCE)-all::

after-$(FW_INSTANCE)-all::

internal-$(FW_TYPE)-all:: before-$(FW_INSTANCE)-all internal-$(FW_TYPE)-all_ after-$(FW_INSTANCE)-all

before-$(FW_INSTANCE)-stage::

after-$(FW_INSTANCE)-stage::

internal-$(FW_TYPE)-stage:: before-$(FW_INSTANCE)-stage internal-$(FW_TYPE)-stage_ after-$(FW_INSTANCE)-stage

define _FW_TEMPLATE_DEFAULT_LINKING_RULE
$$(FW_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
	$$(ECHO_LINKING)$$(TARGET_CXX) $$(ALL_LDFLAGS) -o $$@ $$^$$(ECHO_END)
ifeq ($$(DEBUG),)
	$$(ECHO_STRIPPING)$$(TARGET_STRIP) $$(TARGET_STRIP_FLAGS) $$@$$(ECHO_END)
endif
ifneq ($$(FW_CODESIGN_COMMANDLINE),)
	$$(ECHO_SIGNING)$$(FW_CODESIGN_COMMANDLINE) $$@$$(ECHO_END)
endif
endef

define _FW_TEMPLATE_NOWARNING_LINKING_RULE
$$(FW_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
	$$(ECHO_LINKING)$$(TARGET_CXX) $$(ALL_LDFLAGS) -o $$@ $$^$$(ECHO_END)
ifeq ($$(DEBUG),)
	$$(ECHO_STRIPPING)$$(TARGET_STRIP) $$(TARGET_STRIP_FLAGS) $$@$$(ECHO_END)
endif
ifneq ($$(FW_CODESIGN_COMMANDLINE),)
	$$(ECHO_SIGNING)$$(FW_CODESIGN_COMMANDLINE) $$@$$(ECHO_END)
endif
endef
