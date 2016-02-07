.PHONY: before-$(THEOS_CURRENT_INSTANCE)-all after-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all \
	before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage

__ALL_FILES = $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FILES) $($(THEOS_CURRENT_INSTANCE)_OBJCC_FILES) $($(THEOS_CURRENT_INSTANCE)_LOGOS_FILES) $($(THEOS_CURRENT_INSTANCE)_OBJC_FILES) $($(THEOS_CURRENT_INSTANCE)_CC_FILES) $($(THEOS_CURRENT_INSTANCE)_C_FILES)
__ON_FILES = $(filter-out -%,$(__ALL_FILES))
__OFF_FILES = $(patsubst -%,%,$(filter -%,$(__ALL_FILES)))
_FILES = $(strip $(filter-out $(__OFF_FILES),$(__ON_FILES)))
OBJ_FILES = $(strip $(patsubst %,%.$(_THEOS_OBJ_FILE_TAG).o,$(_FILES)))
SWIFT_FILES = $(filter %.swift,$(_FILES))

_OBJC_FILE_COUNT = $(words $(filter %.m %.mm %.x %.xm %.xi %.xmi,$(_FILES)))
_OBJCC_FILE_COUNT = $(words $(filter %.mm %.xm %.xmi,$(_FILES)))
_SWIFT_FILE_COUNT = $(words $(filter %.swift %.xswift,$(_FILES)))

# This is := because it would otherwise be evaluated immediately afterwards.
_SUBPROJECTS := $(strip $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,SUBPROJECTS))
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
ifneq ($(_OBJC_FILE_COUNT)$(_SWIFT_FILE_COUNT),00)
	_THEOS_INTERNAL_LDFLAGS += -lobjc -framework Foundation -framework CoreFoundation
endif

# In addition, if we have any Objective-C++, add the ObjC++ linker flags.
ifneq ($(_OBJCC_FILE_COUNT),0)
	_THEOS_INTERNAL_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
endif

# If we have any Swift objects, add Swift libraries to the linker search path.
# Also tell the linker to find these libraries in /usr/lib/libswift/<version>.
ifneq ($(_SWIFT_FILE_COUNT),0)
	_THEOS_INTERNAL_LDFLAGS += -L$(_THEOS_TARGET_SWIFT_LDPATH) -rpath /usr/lib/libswift/$(_THEOS_TARGET_SWIFT_VERSION)
endif

# Add all frameworks from the type and instance.
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FRAMEWORKS),-framework $(framework))

# Add all libraries from the type and instance.
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$($(_THEOS_CURRENT_TYPE)_LIBRARIES),-l$(library))
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LIBRARIES),-l$(library))

# Add all private frameworks from the type and instance, as well as -F for the private framework dir.
ifneq ($(words $($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS)$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS)),0)
	_THEOS_INTERNAL_OBJCFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH)
	_THEOS_INTERNAL_SWIFTFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH)
	_THEOS_INTERNAL_LDFLAGS += -F$(TARGET_PRIVATE_FRAMEWORK_PATH)
endif

_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS),-framework $(framework))

# Add extra frameworks (ones in $THEOS/lib).
ifneq ($(words $($(_THEOS_CURRENT_TYPE)_EXTRA_FRAMEWORKS)$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,EXTRA_FRAMEWORKS)),0)
	_THEOS_INTERNAL_OBJCFLAGS += -F$(THEOS)/lib
	_THEOS_INTERNAL_SWIFTFLAGS += -F$(THEOS)/lib
	_THEOS_INTERNAL_LDFLAGS += -F$(THEOS)/lib
endif

_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_EXTRA_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,EXTRA_FRAMEWORKS),-framework $(framework))

# Add weak frameworks.
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_WEAK_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,WEAK_FRAMEWORKS),-weak_framework $(framework))

# Add weak libraries.
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$($(_THEOS_CURRENT_TYPE)_WEAK_LIBRARIES),-weak_library$(library))
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,WEAK_LIBRARIES),-weak_library$(library))

ifneq ($($(THEOS_CURRENT_INSTANCE)_$(_THEOS_TARGET_NAME_DEFINE)_ARCHS),)
TARGET_ARCHS = $($(THEOS_CURRENT_INSTANCE)_$(_THEOS_TARGET_NAME_DEFINE)_ARCHS)
else
ifneq ($($(_THEOS_TARGET_NAME_DEFINE)_ARCHS),)
TARGET_ARCHS = $($(_THEOS_TARGET_NAME_DEFINE)_ARCHS)
else
ifneq ($($(THEOS_CURRENT_INSTANCE)_ARCHS),)
TARGET_ARCHS = $($(THEOS_CURRENT_INSTANCE)_ARCHS)
else
TARGET_ARCHS = $(ARCHS)
endif
endif
endif

ifeq ($(_THEOS_PLATFORM_LIPO),)
ALL_ARCHFLAGS = $(foreach ARCH,$(TARGET_ARCHS),-arch $(ARCH))
PREPROCESS_ARCH_FLAGS = $(foreach ARCH,$(NEUTRAL_ARCH),-arch $(ARCH))
THEOS_CURRENT_ARCH = $(TARGET_ARCHS)
else
ALL_ARCHFLAGS = -arch $(THEOS_CURRENT_ARCH)
PREPROCESS_ARCH_FLAGS = $(ALL_ARCHFLAGS)
endif

ALL_PFLAGS = $(_THEOS_INTERNAL_CFLAGS) $(_THEOS_TARGET_CFLAGS) $(ADDITIONAL_CFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CFLAGS) $(call __schema_var_all,,CFLAGS) $($(<)_CFLAGS) -DTHEOS_INSTANCE_NAME="\"$(THEOS_CURRENT_INSTANCE)\""
ifneq ($(_THEOS_PLATFORM_LIPO),)
ALL_PFLAGS += $($(THEOS_CURRENT_ARCH)_CFLAGS)
_THEOS_INTERNAL_LDFLAGS += $($(THEOS_CURRENT_ARCH)_LDFLAGS)
endif
ALL_CFLAGS = $(ALL_PFLAGS) $(ALL_ARCHFLAGS)
ALL_CCFLAGS = $(_THEOS_INTERNAL_CCFLAGS) $(ADDITIONAL_CCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CCFLAGS) $(call __schema_var_all,,CCFLAGS)
ALL_OBJCFLAGS = $(_THEOS_INTERNAL_OBJCFLAGS) $(_THEOS_TARGET_OBJCFLAGS) $(ADDITIONAL_OBJCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCFLAGS) $(call __schema_var_all,,OBJCFLAGS)
ALL_OBJCCFLAGS = $(_THEOS_INTERNAL_OBJCCFLAGS) $(ADDITIONAL_OBJCCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCCFLAGS) $(call __schema_var_all,,OBJCCFLAGS)
ALL_SWIFTFLAGS = $(_THEOS_INTERNAL_SWIFTFLAGS) $(_THEOS_TARGET_SWIFTFLAGS) $(ADDITIONAL_SWIFTFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCCFLAGS) $(call __schema_var_all,,SWIFTFLAGS)
ALL_LOGOSFLAGS = $(_THEOS_INTERNAL_LOGOSFLAGS) $(ADDITIONAL_LOGOSFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LOGOSFLAGS) $(call __schema_var_all,,LOGOSFLAGS)

ALL_LDFLAGS = $(_THEOS_INTERNAL_LDFLAGS) $(ADDITIONAL_LDFLAGS) $(_THEOS_TARGET_LDFLAGS) $(ALL_ARCHFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LDFLAGS) $(call __schema_var_all,,LDFLAGS)

ifneq ($(TARGET_CODESIGN),)
_THEOS_CODESIGN_COMMANDLINE = CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(ECHO_UNBUFFERED) $(TARGET_CODESIGN) $(or $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CODESIGN_FLAGS),$(TARGET_CODESIGN_FLAGS))
else
_THEOS_CODESIGN_COMMANDLINE =
endif

ALL_STRIP_FLAGS = $(or $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,STRIP_FLAGS),$(TARGET_STRIP_FLAGS))

_THEOS_OBJ_FILE_TAG = $(call __simplify,_THEOS_OBJ_FILE_TAG,$(shell echo "$(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(ALL_LOGOSFLAGS)" | $(_THEOS_PLATFORM_MD5SUM) | cut -c1-8))
_THEOS_OUT_FILE_TAG = $(call __simplify,_THEOS_OUT_FILE_TAG,$(shell echo "$(ALL_STRIP_FLAGS) $(_THEOS_CODESIGN_COMMANDLINE)" | $(_THEOS_PLATFORM_MD5SUM) | cut -c1-8))

_THEOS_USE_MAKEDEPS := $(_THEOS_FALSE)

ifeq ($(call __theos_bool,$(USE_MAKEDEPS)),$(_THEOS_TRUE))
_THEOS_USE_MAKEDEPS := $(_THEOS_TRUE)
endif

ifneq ($(_THEOS_MAKE_PARALLEL_BUILDING)$(_THEOS_MAKE_PARALLEL),yesyes)
ifneq ($(_THEOS_MAKE_PARALLEL_BUILDING),no)
override _THEOS_OBJ_FILE_TAG := dummy
_THEOS_USE_MAKEDEPS := $(_THEOS_FALSE)
endif
endif

ifeq ($(_THEOS_USE_MAKEDEPS),$(_THEOS_TRUE))
MAKEDEP_FILES = $(addprefix $(THEOS_OBJ_DIR)/,$(strip $(patsubst %,%.$(_THEOS_OBJ_FILE_TAG).md,$(_FILES))))
-include $(MAKEDEP_FILES)
endif

before-$(THEOS_CURRENT_INSTANCE)-all after-$(THEOS_CURRENT_INSTANCE)-all::
	@for i in $(_FILES); do \
	    if [ ! -f "$$i" ]; then \
	        $(PRINT_FORMAT_ERROR) "File $$i does not exist." 2>&1; \
	        exit 1; \
	    fi; \
	done

internal-$(_THEOS_CURRENT_TYPE)-all:: before-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all_ after-$(THEOS_CURRENT_INSTANCE)-all
	@:

before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage::
	@:

internal-$(_THEOS_CURRENT_TYPE)-stage:: before-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage_ after-$(THEOS_CURRENT_INSTANCE)-stage
	@:

.SUFFIXES:

.SUFFIXES: .m .mm .c .cc .cpp .xm

MDFLAGS = -MP -MT "$@ $(subst .md,.o,$@)" -MM
$(THEOS_OBJ_DIR)/%.m.$(_THEOS_OBJ_FILE_TAG).o: %.m
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.m.$(_THEOS_OBJ_FILE_TAG).md: %.m
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x objective-c -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.mi.$(_THEOS_OBJ_FILE_TAG).o: %.mi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c-cpp-output -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mm.$(_THEOS_OBJ_FILE_TAG).o: %.mm
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mm.$(_THEOS_OBJ_FILE_TAG).md: %.mm
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x objective-c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.mii.$(_THEOS_OBJ_FILE_TAG).o: %.mii
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++-cpp-output -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c.$(_THEOS_OBJ_FILE_TAG).o: %.c
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c.$(_THEOS_OBJ_FILE_TAG).md: %.c
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x c -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.i.$(_THEOS_OBJ_FILE_TAG).o: %.i
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c-cpp-output -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.s.$(_THEOS_OBJ_FILE_TAG).o: %.s
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x assembler -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.S.$(_THEOS_OBJ_FILE_TAG).o: %.S
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x assembler-with-cpp -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.S.$(_THEOS_OBJ_FILE_TAG).md: %.S
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x assembler-with-cpp -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.cc.$(_THEOS_OBJ_FILE_TAG).o: %.cc
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cc.$(_THEOS_OBJ_FILE_TAG).md: %.cc
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.cp.$(_THEOS_OBJ_FILE_TAG).o: %.cp
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cp.$(_THEOS_OBJ_FILE_TAG).md: %.cp
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.cxx.$(_THEOS_OBJ_FILE_TAG).o: %.cxx
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cxx.$(_THEOS_OBJ_FILE_TAG).md: %.cxx
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.cpp.$(_THEOS_OBJ_FILE_TAG).o: %.cpp
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cpp.$(_THEOS_OBJ_FILE_TAG).md: %.cpp
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.c++.$(_THEOS_OBJ_FILE_TAG).o: %.c++
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c++.$(_THEOS_OBJ_FILE_TAG).md: %.c++
ifneq ($(THEOS_CURRENT_ARCH),)
	$(ECHO_NOTHING)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< $(MDFLAGS) -o $@$(ECHO_END)
endif

$(THEOS_OBJ_DIR)/%.ii.$(_THEOS_OBJ_FILE_TAG).o: %.ii
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++-cpp-output -c $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.swift.$(_THEOS_OBJ_FILE_TAG).o: %.swift
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(TARGET_SWIFT) -frontend -emit-object -c $(ALL_SWIFTFLAGS) -target $(THEOS_CURRENT_ARCH)-$(_THEOS_TARGET_SWIFT_TARGET) -primary-file $< $(SWIFT_FILES) -o $@$(ECHO_END)


$(THEOS_OBJ_DIR)/%.x.$(_THEOS_OBJ_FILE_TAG).o: %.x
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $(THEOS_OBJ_DIR)/$<.m$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -c -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $(THEOS_OBJ_DIR)/$<.m -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.m$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xm.$(_THEOS_OBJ_FILE_TAG).o: %.xm
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $(THEOS_OBJ_DIR)/$<.mm$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -c -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(THEOS_OBJ_DIR)/$<.mm -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.mm$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xi.$(_THEOS_OBJ_FILE_TAG).o: %.xi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -E -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS) $(ALL_PFLAGS) $(PREPROCESS_ARCH_FLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) -include substrate.h $< > $(THEOS_OBJ_DIR)/$<.pre && $(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $(THEOS_OBJ_DIR)/$<.pre > $(THEOS_OBJ_DIR)/$<.mi $(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(_THEOS_TARGET_ONLY_OBJCFLAGS) $(THEOS_OBJ_DIR)/$<.mi -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.pre $(THEOS_OBJ_DIR)/$<.mi$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xmi.$(_THEOS_OBJ_FILE_TAG).o: %.xmi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -E -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS) $(ALL_PFLAGS) $(PREPROCESS_ARCH_FLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) -include substrate.h $< > $(THEOS_OBJ_DIR)/$<.pre && $(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $(THEOS_OBJ_DIR)/$<.pre > $(THEOS_OBJ_DIR)/$<.mii $(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(THEOS_OBJ_DIR)/$<.mii -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.pre $(THEOS_OBJ_DIR)/$<.mii$(ECHO_END)

define _THEOS_TEMPLATE_DEFAULT_LINKING_RULE
ifeq ($(_THEOS_PLATFORM_LIPO),)
ifneq ($$(TARGET_CODESIGN),)
.INTERMEDIATE: $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
$$(THEOS_OBJ_DIR)/$(1): $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) "$$<" && mv "$$<" "$$@"$$(ECHO_END)
$$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned: $$(OBJ_FILES_TO_LINK)
else
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
endif
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LD) $$(ALL_LDFLAGS) -o "$$@" $$^ | (grep -v 'usr/lib/dylib1.o, missing required architecture' || true)$$(ECHO_END)
ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
else
ifeq ($(THEOS_CURRENT_ARCH),)

ARCH_FILES_TO_LINK := $(addsuffix /$(1),$(addprefix $(THEOS_OBJ_DIR)/,$(TARGET_ARCHS)))
$$(THEOS_OBJ_DIR)/%/$(1): $(__ALL_FILES)
	@ \
	mkdir -p $(THEOS_OBJ_DIR)/$$*; \
	$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going \
		internal-$(_THEOS_CURRENT_TYPE)-$(_THEOS_CURRENT_OPERATION) \
		_THEOS_CURRENT_TYPE="$(_THEOS_CURRENT_TYPE)" \
		THEOS_CURRENT_INSTANCE="$(THEOS_CURRENT_INSTANCE)" \
		_THEOS_CURRENT_OPERATION="$(_THEOS_CURRENT_OPERATION)" \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" \
		THEOS_CURRENT_ARCH="$$*"

ifneq ($$(TARGET_CODESIGN),)
.INTERMEDIATE: $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
$(THEOS_OBJ_DIR)/$(1): $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) "$$<" && mv "$$<" "$$@"$$(ECHO_END)
$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned: $$(ARCH_FILES_TO_LINK)
else
$(THEOS_OBJ_DIR)/$(1): $$(ARCH_FILES_TO_LINK)
endif
	$(ECHO_MERGING)$(ECHO_UNBUFFERED)$(_THEOS_PLATFORM_LIPO) $(foreach ARCH,$(TARGET_ARCHS),-arch $(ARCH) $(THEOS_OBJ_DIR)/$(ARCH)/$(1)) -create -output "$$@"$(ECHO_END)

else
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
	$$(ECHO_NOTHING)mkdir -p $(shell dirname "$(THEOS_OBJ_DIR)/$(1)")$$(ECHO_END)
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LD) $$(ALL_LDFLAGS) -o "$$@" $$^ | (grep -v 'usr/lib/dylib1.o, missing required architecture' || true)$$(ECHO_END)
ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endif
endif

endef

$(eval $(call __mod,instance/rules.mk))
