.PHONY: before-$(THEOS_CURRENT_INSTANCE)-all after-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all \
	before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage

__ALL_FILES = $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FILES) $($(THEOS_CURRENT_INSTANCE)_OBJCC_FILES) $($(THEOS_CURRENT_INSTANCE)_LOGOS_FILES) $($(THEOS_CURRENT_INSTANCE)_OBJC_FILES) $($(THEOS_CURRENT_INSTANCE)_CC_FILES) $($(THEOS_CURRENT_INSTANCE)_C_FILES)
__ON_FILES = $(filter-out -%,$(__ALL_FILES))
__OFF_FILES = $(patsubst -%,%,$(filter -%,$(__ALL_FILES)))
_FILES = $(strip $(filter-out $(__OFF_FILES),$(__ON_FILES)))
OBJ_FILES = $(strip $(patsubst %,%.$(_THEOS_OBJ_FILE_TAG).o,$(_FILES)))

_OBJC_FILE_COUNT = $(words $(filter %.m %.mm %.x %.xm %.xi %.xmi,$(_FILES)))
_OBJCC_FILE_COUNT = $(words $(filter %.mm %.xm %.xmi,$(_FILES)))

_SUBPROJECTS = $(strip $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,SUBPROJECTS))
ifneq ($(_SUBPROJECTS),)
SUBPROJECT_OBJ_FILES = $(foreach d, $(_SUBPROJECTS), $(THEOS_BUILD_DIR)/$(firstword $(subst :, ,$(d)))/$(THEOS_OBJ_DIR_NAME)/$(or $(word 2,$(subst :, ,$(d))),*).$(THEOS_SUBPROJECT_PRODUCT))
#SUBPROJECT_OBJ_FILES = $(addsuffix /$(THEOS_OBJ_DIR_NAME)/$(THEOS_SUBPROJECT_PRODUCT), $(addprefix $(THEOS_BUILD_DIR)/,$($(THEOS_CURRENT_INSTANCE)_SUBPROJECTS)))
SUBPROJECT_LDFLAGS = $(shell sort $(foreach d,$(_SUBPROJECTS),$(THEOS_BUILD_DIR)/$(firstword $(subst :, ,$(d)))/$(THEOS_OBJ_DIR_NAME)/$(or $(word 2,$(subst :, ,$(d))),*).ldflags) | uniq)
_THEOS_INTERNAL_LDFLAGS += $(SUBPROJECT_LDFLAGS)
endif

OBJ_FILES_TO_LINK = $(strip $(addprefix $(THEOS_OBJ_DIR)/,$(OBJ_FILES)) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJ_FILES) $(SUBPROJECT_OBJ_FILES))
_OBJ_DIR_STAMPS = $(sort $(foreach o,$(filter $(THEOS_OBJ_DIR)%,$(OBJ_FILES_TO_LINK)),$(dir $o).stamp))

ADDITIONAL_CPPFLAGS += $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CPPFLAGS)

# If we have any Objective-C objects, link Foundation and libobjc.
ifneq ($(_OBJC_FILE_COUNT),0)
	_THEOS_INTERNAL_LDFLAGS += -lobjc -framework Foundation -framework CoreFoundation
endif

# In addition, if we have any Objective-C++, add the ObjC++ linker flags.
ifneq ($(_OBJCC_FILE_COUNT),0)
	_THEOS_INTERNAL_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
endif

# Add all frameworks from the type and instance.
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FRAMEWORKS),-framework $(framework))

# Add all libraries from the type and instance.
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$($(_THEOS_CURRENT_TYPE)_LIBRARIES),-l$(library))
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LIBRARIES),-l$(library))

# Add all private frameworks from the type and instance, as well as -F for the private framework dir.
ifneq ($(words $($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS)$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS)),0)
	_THEOS_INTERNAL_OBJCFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
	_THEOS_INTERNAL_LDFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
endif

_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS),-framework $(framework))

ALL_CFLAGS = $(_THEOS_INTERNAL_CFLAGS) $(_THEOS_TARGET_CFLAGS) $(ADDITIONAL_CFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CFLAGS) $(call __schema_var_all,,CFLAGS)
ALL_CCFLAGS = $(ADDITIONAL_CCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CCFLAGS) $(call __schema_var_all,,CCFLAGS)
ALL_OBJCFLAGS = $(_THEOS_INTERNAL_OBJCFLAGS) $(_THEOS_TARGET_OBJCFLAGS) $(ADDITIONAL_OBJCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCFLAGS) $(call __schema_var_all,,OBJCFLAGS)
ALL_OBJCCFLAGS = $(ADDITIONAL_OBJCCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCCFLAGS) $(call __schema_var_all,,OBJCCFLAGS)
ALL_LOGOSFLAGS = $(_THEOS_INTERNAL_LOGOSFLAGS) $(ADDITIONAL_LOGOSFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LOGOSFLAGS) $(call __schema_var_all,,LOGOSFLAGS)

ALL_LDFLAGS = $(_THEOS_INTERNAL_LDFLAGS) $(ADDITIONAL_LDFLAGS) $(_THEOS_TARGET_LDFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LDFLAGS) $(call __schema_var_all,,LDFLAGS)

ifneq ($(TARGET_CODESIGN),)
_THEOS_CODESIGN_COMMANDLINE = CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(TARGET_CODESIGN) $(or $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CODESIGN_FLAGS),$(TARGET_CODESIGN_FLAGS))
else
_THEOS_CODESIGN_COMMANDLINE = 
endif

ALL_STRIP_FLAGS = $(or $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,STRIP_FLAGS),$(TARGET_STRIP_FLAGS))

_THEOS_FLAG_HASH_TEMP = $(shell echo "$(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(ALL_LOGOSFLAGS)" | $(_THEOS_PLATFORM_MD5SUM) | cut -c1-8)
_THEOS_OUTFILE_FLAG_HASH_TEMP = $(shell echo "$(ALL_STRIP_FLAGS) $(_THEOS_CODESIGN_COMMANDLINE)" | $(_THEOS_PLATFORM_MD5SUM) | cut -c1-8)

ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING)$(_THEOS_MAKE_PARALLEL),yesyes)
# We're in the last stage of building.
_THEOS_OBJ_FILE_TAG := $(_THEOS_FLAG_HASH_TEMP)
_THEOS_OUT_FILE_TAG := $(_THEOS_OUTFILE_FLAG_HASH_TEMP)
else
ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING),no)
_THEOS_OBJ_FILE_TAG := $(_THEOS_FLAG_HASH_TEMP)
_THEOS_OUT_FILE_TAG := $(_THEOS_OUTFILE_FLAG_HASH_TEMP)
else
_THEOS_OBJ_FILE_TAG := dummy
endif
endif

before-$(THEOS_CURRENT_INSTANCE)-all::

after-$(THEOS_CURRENT_INSTANCE)-all::

internal-$(_THEOS_CURRENT_TYPE)-all:: before-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all_ after-$(THEOS_CURRENT_INSTANCE)-all

before-$(THEOS_CURRENT_INSTANCE)-stage::

after-$(THEOS_CURRENT_INSTANCE)-stage::

internal-$(_THEOS_CURRENT_TYPE)-stage:: before-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage_ after-$(THEOS_CURRENT_INSTANCE)-stage

.SUFFIXES:

.SUFFIXES: .m .mm .c .cc .cpp .xm

$(THEOS_OBJ_DIR)/%.m.$(_THEOS_OBJ_FILE_TAG).o: %.m
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mi.$(_THEOS_OBJ_FILE_TAG).o: %.mi
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c-cpp-output -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mm.$(_THEOS_OBJ_FILE_TAG).o: %.mm
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c++ -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mii.$(_THEOS_OBJ_FILE_TAG).o: %.mii
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c++-cpp-output -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c.$(_THEOS_OBJ_FILE_TAG).o: %.c
	$(ECHO_COMPILING)$(TARGET_CXX) -x c -c $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.i.$(_THEOS_OBJ_FILE_TAG).o: %.i
	$(ECHO_COMPILING)$(TARGET_CXX) -x c-cpp-output -c $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.s.$(_THEOS_OBJ_FILE_TAG).o: %.s
	$(ECHO_COMPILING)$(TARGET_CXX) -x assembler -c $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.S.$(_THEOS_OBJ_FILE_TAG).o: %.S
	$(ECHO_COMPILING)$(TARGET_CXX) -x assembler-with-cpp -c $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cc.$(_THEOS_OBJ_FILE_TAG).o: %.cc
	$(ECHO_COMPILING)$(TARGET_CXX) -x c++ -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cp.$(_THEOS_OBJ_FILE_TAG).o: %.cp
	$(ECHO_COMPILING)$(TARGET_CXX) -x c++ -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cxx.$(_THEOS_OBJ_FILE_TAG).o: %.cxx
	$(ECHO_COMPILING)$(TARGET_CXX) -x c++ -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cpp.$(_THEOS_OBJ_FILE_TAG).o: %.cpp
	$(ECHO_COMPILING)$(TARGET_CXX) -x c++ -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c++.$(_THEOS_OBJ_FILE_TAG).o: %.c++
	$(ECHO_COMPILING)$(TARGET_CXX) -x c++ -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.ii.$(_THEOS_OBJ_FILE_TAG).o: %.ii
	$(ECHO_COMPILING)$(TARGET_CXX) -x c++-cpp-output -c $(ALL_CFLAGS) $< -o $@$(ECHO_END)


$(THEOS_OBJ_DIR)/%.x.$(_THEOS_OBJ_FILE_TAG).o: %.x
	$(ECHO_PREPROCESSING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $(THEOS_OBJ_DIR)/$<.m$(ECHO_END)
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c -c -I"$(call __clean_pwd,$(dir $<))" $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) -include "logos/logos.h" $(THEOS_OBJ_DIR)/$<.m -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.m$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xm.$(_THEOS_OBJ_FILE_TAG).o: %.xm
	$(ECHO_PREPROCESSING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $(THEOS_OBJ_DIR)/$<.mm$(ECHO_END)
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c++ -c -I"$(call __clean_pwd,$(dir $<))" $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) -include "logos/logos.h" $(THEOS_OBJ_DIR)/$<.mm -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.mm$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xi.$(_THEOS_OBJ_FILE_TAG).o: %.xi
	$(ECHO_PREPROCESSING)$(TARGET_CXX) -x objective-c -E -I"$(call __clean_pwd,$(dir $<))" $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) -include "logos/logos.h" -include substrate.h $< > $(THEOS_OBJ_DIR)/$<.pre && $(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $(THEOS_OBJ_DIR)/$<.pre > $(THEOS_OBJ_DIR)/$<.mi $(ECHO_END)
	$(ECHO_COMPILING)$(TARGET_CXX) -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $(THEOS_OBJ_DIR)/$<.mi -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.pre $(THEOS_OBJ_DIR)/$<.mi$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xmi.$(_THEOS_OBJ_FILE_TAG).o: %.xmi
	$(ECHO_PREPROCESSING)$(TARGET_CXX) -x objective-c++ -E -I"$(call __clean_pwd,$(dir $<))" $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) -include "logos/logos.h" -include substrate.h $< > $(THEOS_OBJ_DIR)/$<.pre && $(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $(THEOS_OBJ_DIR)/$<.pre > $(THEOS_OBJ_DIR)/$<.mii $(ECHO_END)
	$(ECHO_COMPILING)$(TARGET_CXX) -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(THEOS_OBJ_DIR)/$<.mii -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.pre $(THEOS_OBJ_DIR)/$<.mii$(ECHO_END)

define _THEOS_TEMPLATE_DEFAULT_LINKING_RULE
ifneq ($$(TARGET_CODESIGN),)
.INTERMEDIATE: $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
$$(THEOS_OBJ_DIR)/$(1): $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) "$$<"; mv "$$<" "$$@"$$(ECHO_END)
$$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned: $$(OBJ_FILES_TO_LINK)
else
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
endif
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
	$$(ECHO_LINKING)$$(TARGET_LD) $$(ALL_LDFLAGS) -o "$$@" $$^$$(ECHO_END)
ifeq ($$(findstring DEBUG,$$(THEOS_SCHEMA)),)
	$$(ECHO_STRIPPING)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endef

$(eval $(call __mod,instance/rules.mk))
