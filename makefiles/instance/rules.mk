.PHONY: before-$(THEOS_CURRENT_INSTANCE)-all after-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all \
	before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage \
	internal-$(THEOS_CURRENT_INSTANCE)-swift-support internal-$(THEOS_CURRENT_INSTANCE)-orion

__USER_FILES = $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FILES) $($(THEOS_CURRENT_INSTANCE)_OBJCC_FILES) $($(THEOS_CURRENT_INSTANCE)_LOGOS_FILES) $($(THEOS_CURRENT_INSTANCE)_OBJC_FILES) $($(THEOS_CURRENT_INSTANCE)_CC_FILES) $($(THEOS_CURRENT_INSTANCE)_C_FILES) $($(THEOS_CURRENT_INSTANCE)_SWIFT_FILES)
__ALL_FILES = $(__USER_FILES) $(__TEMP_FILES)
__ON_FILES = $(filter-out -%,$(__ALL_FILES))
__OFF_FILES = $(patsubst -%,%,$(filter -%,$(__ALL_FILES)))
_FILES = $(strip $(filter-out $(__OFF_FILES),$(__ON_FILES)))
OBJ_FILES = $(strip $(patsubst %,%.$(_THEOS_OBJ_FILE_TAG).o,$(_FILES)))
OBJC_FILES = $(filter %.m %.mm %.x %.xm %.xi %.xmi,$(_FILES))
OBJCC_FILES = $(filter %.mm %.xm %.xmi,$(_FILES))
SWIFT_FILES = $(filter %.swift,$(_FILES))
XSWIFT_FILES = $(filter %.x.swift,$(_FILES))

_OBJC_FILE_COUNT = $(words $(OBJC_FILES))
_OBJCC_FILE_COUNT = $(words $(OBJCC_FILES))
_SWIFT_FILE_COUNT = $(words $(SWIFT_FILES))
_XSWIFT_FILE_COUNT = $(words $(XSWIFT_FILES))

# we have to keep this in a subdir so we can add it as a header search path without unexpected consequences
_SWIFTMODULE_HEADER = $(THEOS_OBJ_DIR)/generated/$(THEOS_CURRENT_INSTANCE)-Swift.h
_ORION_GLUE = $(THEOS_OBJ_DIR)/generated/$(THEOS_CURRENT_INSTANCE).xc.swift
_SWIFT_STAMP = $(THEOS_OBJ_DIR)/.swift-stamp

# This is := because it would otherwise be evaluated immediately afterwards.
_SUBPROJECTS := $(strip $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,SUBPROJECTS))
ifneq ($(_SUBPROJECTS),)
SUBPROJECT_OBJ_FILES = $(foreach d, $(_SUBPROJECTS), $(THEOS_OBJ_DIR)/$(or $(word 2,$(subst :, ,$(d))),*).$(THEOS_SUBPROJECT_PRODUCT))
SUBPROJECT_LDFLAGS = $(shell sort $(foreach d,$(_SUBPROJECTS),$(THEOS_OBJ_DIR)/$(or $(word 2,$(subst :, ,$(d))),*).ldflags) | uniq)
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
ifneq ($(_SWIFT_FILE_COUNT),0)
	_THEOS_INTERNAL_LDFLAGS += $(foreach path,$(_THEOS_TARGET_SWIFT_LDPATHS),-L$(path))
ifneq ($(_THEOS_CURRENT_TYPE),subproject)
	_THEOS_INTERNAL_LDFLAGS += $(_THEOS_TARGET_SWIFT_LDFLAGS)
endif
endif

ifneq ($(_SWIFT_FILE_COUNT),0)
# The markers/swift_support dir serves as an atomic marker of whether swift support
# has been built and the io mutex has been created (if necessary). mkdir is effectively
# used as a test-and-set to avoid TOCTOU.
before-$(THEOS_CURRENT_INSTANCE)-all::
	$(ECHO_NOTHING)if mkdir $(_THEOS_SWIFT_MARKERS_DIR)/swift_support 2>/dev/null; then \
		$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) internal-$(THEOS_CURRENT_INSTANCE)-swift-support THEOS_START_SWIFT_SUPPORT=$(_THEOS_TRUE) || exit $$?; \
	else :; \
	fi$(ECHO_END)
ifneq ($(_XSWIFT_FILE_COUNT),0)
	$(ECHO_NOTHING)if mkdir $(_THEOS_SWIFT_MARKERS_DIR)/orion 2>/dev/null; then \
		$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) internal-$(THEOS_CURRENT_INSTANCE)-orion THEOS_BUILD_ORION=$(_THEOS_TRUE) || exit $$?; \
	else :; \
	fi$(ECHO_END)
endif

ifneq ($(_OBJC_FILE_COUNT),0)
# if both Swift and ObjC files exist
_THEOS_GENERATE_SWIFTMODULE_HEADER = $(_THEOS_TRUE)
_THEOS_SWIFTMODULE_HEADER_DIR = $(dir $(_SWIFTMODULE_HEADER))
_THEOS_SWIFT_SWIFTMODULE_HEADER_FLAG = -emit-objc-header-path $(_SWIFTMODULE_HEADER)
_THEOS_INTERNAL_IFLAGS_C += -I$(_THEOS_SWIFTMODULE_HEADER_DIR)
endif
endif

ifneq ($(_XSWIFT_FILE_COUNT),0)
# temp files are included in __FILES, but not in __USER_FILES
__TEMP_FILES += $(_ORION_GLUE)
endif

# If we have a Bridging Header, import it in Swift
_THEOS_INTERNAL_SWIFT_BRIDGING_HEADER = $(or $($(THEOS_CURRENT_INSTANCE)_SWIFT_BRIDGING_HEADER),$(THEOS_CURRENT_INSTANCE)-Bridging-Header.h)
ifeq ($(call __exists,$(_THEOS_INTERNAL_SWIFT_BRIDGING_HEADER)),$(_THEOS_TRUE))
	_THEOS_INTERNAL_IFLAGS_SWIFT += -import-objc-header $(_THEOS_INTERNAL_SWIFT_BRIDGING_HEADER)
endif
_THEOS_INTERNAL_SWIFTFLAGS += -swift-version $(or $($(THEOS_CURRENT_INSTANCE)_SWIFT_VERSION),5)

ifeq ($(filter main.swift,$(notdir $(SWIFT_FILES))),)
_THEOS_INTERNAL_SWIFTFLAGS += -parse-as-library
endif

# Add all frameworks from the type and instance.
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,FRAMEWORKS),-framework $(framework))

# Add all libraries from the type and instance.
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$($(_THEOS_CURRENT_TYPE)_LIBRARIES),-l$(library))
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LIBRARIES),-l$(library))

_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_PRIVATE_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,PRIVATE_FRAMEWORKS),-framework $(framework))

_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_EXTRA_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,EXTRA_FRAMEWORKS),-framework $(framework))

# Add weak frameworks.
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$($(_THEOS_CURRENT_TYPE)_WEAK_FRAMEWORKS),-framework $(framework))
_THEOS_INTERNAL_LDFLAGS += $(foreach framework,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,WEAK_FRAMEWORKS),-weak_framework $(framework))

# Add weak libraries.
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$($(_THEOS_CURRENT_TYPE)_WEAK_LIBRARIES),-weak_library $(library))
_THEOS_INTERNAL_LDFLAGS += $(foreach library,$(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,WEAK_LIBRARIES),-weak_library $(library))

# Add rpaths for rootless
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	_THEOS_INTERNAL_LDFLAGS += -rpath $(THEOS_PACKAGE_INSTALL_PREFIX)/Library/Frameworks -rpath $(THEOS_PACKAGE_INSTALL_PREFIX)/usr/lib
endif

_THEOS_INTERNAL_CFLAGS += -D THEOS_PACKAGE_INSTALL_PREFIX="\"$(THEOS_PACKAGE_INSTALL_PREFIX)\""

ifneq ($($(THEOS_CURRENT_INSTANCE)_$(_THEOS_TARGET_NAME_DEFINE)_ARCHS),)
TARGET_ARCHS = $($(THEOS_CURRENT_INSTANCE)_$(_THEOS_TARGET_NAME_DEFINE)_ARCHS)
else ifneq ($($(_THEOS_TARGET_NAME_DEFINE)_ARCHS),)
TARGET_ARCHS = $($(_THEOS_TARGET_NAME_DEFINE)_ARCHS)
else ifneq ($($(THEOS_CURRENT_INSTANCE)_ARCHS),)
TARGET_ARCHS = $($(THEOS_CURRENT_INSTANCE)_ARCHS)
else
TARGET_ARCHS = $(ARCHS)
endif

_TARGET_ARCHS_COUNT = $(words $(TARGET_ARCHS))

# The magic behind `make commands`: proxy the compile commands for one arch
# through gen-commands.pl so that we can save them to the commands db
export THEOS_GEN_COMPILE_COMMANDS
ifeq ($(THEOS_GEN_COMPILE_COMMANDS) $(THEOS_CURRENT_ARCH),$(_THEOS_TRUE) $(firstword $(TARGET_ARCHS)))
_TARGET_SWIFTC := $(TARGET_SWIFTC)
# we use PWD instead of THEOS_PROJECT_DIR because the latter always refers to the root level project
# so it isn't correct for subprojects.
ifneq ($(firstword $(_TARGET_SWIFTC)),$(THEOS_BIN_PATH)/gen-commands.pl)
TARGET_SWIFTC = $(THEOS_BIN_PATH)/gen-commands.pl $(_THEOS_TMP_COMPILE_COMMANDS_FILE) $${PWD} swift $(filter $(__USER_FILES),$(SWIFT_FILES)) -- $(_TARGET_SWIFTC)
endif
_TARGET_CXX := $(TARGET_CXX)
ifneq ($(firstword $(_TARGET_CXX)),$(THEOS_BIN_PATH)/gen-commands.pl)
TARGET_CXX = $(THEOS_BIN_PATH)/gen-commands.pl $(_THEOS_TMP_COMPILE_COMMANDS_FILE) $${PWD} cxx $(filter $(__USER_FILES),$<) -- $(_TARGET_CXX)
endif
endif

ifeq ($(TARGET_LIPO),)
ALL_ARCHFLAGS = $(foreach ARCH,$(TARGET_ARCHS),-arch $(ARCH))
PREPROCESS_ARCH_FLAGS = $(foreach ARCH,$(NEUTRAL_ARCH),-arch $(ARCH))
THEOS_CURRENT_ARCH = $(TARGET_ARCHS)
else
ALL_ARCHFLAGS = -arch $(THEOS_CURRENT_ARCH)
PREPROCESS_ARCH_FLAGS = $(ALL_ARCHFLAGS)
endif

ALL_PFLAGS = $(_THEOS_INTERNAL_COLORFLAGS) $(_THEOS_INTERNAL_CFLAGS) $(_THEOS_TARGET_CFLAGS) $(ADDITIONAL_CFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CFLAGS) $(call __schema_var_all,,CFLAGS) $($(<)_CFLAGS) -DTHEOS_INSTANCE_NAME="\"$(THEOS_CURRENT_INSTANCE)\""

_LOCAL_USE_MODULES = $(or $($(THEOS_CURRENT_INSTANCE)_USE_MODULES),$(_THEOS_TRUE))
ifeq ($(call __theos_bool,$(_LOCAL_USE_MODULES)),$(_THEOS_TRUE))
ALL_PFLAGS += $(MODULESFLAGS)
endif

ifneq ($(TARGET_LIPO),)
ALL_PFLAGS += $($(THEOS_CURRENT_ARCH)_CFLAGS)
_THEOS_INTERNAL_LDFLAGS += $($(THEOS_CURRENT_ARCH)_LDFLAGS)
endif
ALL_CFLAGS = $(ALL_PFLAGS) $(ALL_ARCHFLAGS)
ALL_CCFLAGS = $(_THEOS_INTERNAL_CCFLAGS) $(_THEOS_TARGET_CCFLAGS) $(ADDITIONAL_CCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CCFLAGS) $(call __schema_var_all,,CCFLAGS)
ALL_OBJCFLAGS = $(_THEOS_INTERNAL_OBJCFLAGS) $(_THEOS_TARGET_OBJCFLAGS) $(ADDITIONAL_OBJCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCFLAGS) $(call __schema_var_all,,OBJCFLAGS)
ALL_OBJCCFLAGS = $(_THEOS_INTERNAL_OBJCCFLAGS) $(ADDITIONAL_OBJCCFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,OBJCCFLAGS) $(call __schema_var_all,,OBJCCFLAGS)
ALL_SWIFTFLAGS = $(_THEOS_INTERNAL_SWIFTCOLORFLAGS) $(foreach flag,$(ALL_CFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCFLAGS) $(ALL_OBJCCFLAGS),-Xcc $(flag)) $(_THEOS_INTERNAL_SWIFTFLAGS) $(_THEOS_TARGET_SWIFTFLAGS) $(ADDITIONAL_SWIFTFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,SWIFTFLAGS) $(call __schema_var_all,,SWIFTFLAGS)
ALL_ORIONFLAGS = $(_THEOS_INTERNAL_ORIONFLAGS) $(ADDITIONAL_ORIONFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,ORIONFLAGS) $(call __schema_var_all,,ORIONFLAGS)
ALL_LOGOSFLAGS = $(_THEOS_INTERNAL_LOGOSFLAGS) $(ADDITIONAL_LOGOSFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LOGOSFLAGS) $(call __schema_var_all,,LOGOSFLAGS)

ALL_LDFLAGS = $(_THEOS_INTERNAL_COLORFLAGS) $(_THEOS_INTERNAL_LDFLAGS) $(ADDITIONAL_LDFLAGS) $(_THEOS_TARGET_LDFLAGS) $(ALL_ARCHFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,LDFLAGS) $(call __schema_var_all,,LDFLAGS)

ifneq ($(TARGET_CODESIGN),)
_THEOS_CODESIGN_COMMANDLINE = CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(ECHO_UNBUFFERED) $(TARGET_CODESIGN) $(or $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,CODESIGN_FLAGS),$(TARGET_CODESIGN_FLAGS))
else
_THEOS_CODESIGN_COMMANDLINE =
endif

ALL_STRIP_FLAGS = $(or $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,STRIP_FLAGS),$(TARGET_STRIP_FLAGS))

_THEOS_OBJ_FILE_TAG = $(call __simplify,_THEOS_OBJ_FILE_TAG,$(shell echo "$(_THEOS_INTERNAL_IFLAGS_C) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(ALL_LOGOSFLAGS) $(ALL_SWIFTFLAGS) $(ALL_ORIONFLAGS)" | $(_THEOS_PLATFORM_MD5SUM) | cut -c1-8))
_THEOS_OUT_FILE_TAG = $(call __simplify,_THEOS_OUT_FILE_TAG,$(shell echo "$(ALL_STRIP_FLAGS) $(_THEOS_CODESIGN_COMMANDLINE)" | $(_THEOS_PLATFORM_MD5SUM) | cut -c1-8))

ifeq ($(call __theos_bool,$(or $(USE_DEPS),$(_THEOS_TRUE))),$(_THEOS_TRUE))
ALL_DEPFLAGS = -MT $@ -MMD -MP -MF "$(THEOS_OBJ_DIR)/$<.$(_THEOS_OBJ_FILE_TAG).Td"
DEP_FILES = $(strip $(patsubst %,$(THEOS_OBJ_DIR)/%.$(_THEOS_OBJ_FILE_TAG).Td,$(_FILES)))
-include $(DEP_FILES)
endif

ifeq ($(THEOS_START_SWIFT_SUPPORT),$(_THEOS_TRUE))
internal-$(THEOS_CURRENT_INSTANCE)-swift-support::
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/swift-bootstrapper.pl $(_THEOS_PLATFORM_SWIFT) $(THEOS_VENDOR_SWIFT_SUPPORT_PATH) '$(PRINT_FORMAT_BLUE) "Building Swift support tools"' >&2$(ECHO_END)

ifeq ($(_THEOS_INTERNAL_USE_PARALLEL_BUILDING),$(_THEOS_TRUE))
# Don't buffer/synchronize Swift support builder/server output
MAKEFLAGS += -Onone

# The Theos Swift Output Mutex coordinates output from instances of parse-swiftc-output
# since Make's own jobserver doesn't have the required granularity due to a lack of
# information about which Swift file is being compiled
internal-$(THEOS_CURRENT_INSTANCE)-swift-support::
	$(ECHO_NOTHING)rm -f $(_THEOS_SWIFT_MUTEX)$(ECHO_END)
	$(ECHO_NOTHING)touch $(_THEOS_SWIFT_MUTEX)$(ECHO_END)
endif
endif

ifeq ($(THEOS_BUILD_ORION),$(_THEOS_TRUE))
internal-$(THEOS_CURRENT_INSTANCE)-orion::
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/swift-bootstrapper.pl $(_THEOS_PLATFORM_SWIFT) $(THEOS_VENDOR_ORION_PATH) '$(PRINT_FORMAT_BLUE) "Building Orion preprocessor (this may take a while)"' >&2$(ECHO_END)

ifeq ($(_THEOS_INTERNAL_USE_PARALLEL_BUILDING),$(_THEOS_TRUE))
MAKEFLAGS += -Onone
endif
endif

before-$(THEOS_CURRENT_INSTANCE)-all::
ifneq ($(_XSWIFT_FILE_COUNT),0)
ifneq ($(_THEOS_DARWIN_HAS_STABLE_SWIFT),$(_THEOS_TRUE))
ifeq ($(_THEOS_DARWIN_STABLE_SWIFT_VERSION),)
	$(ERROR_BEGIN) "The provided target platform does not currently support Orion." $(ERROR_END)
else
	$(ERROR_BEGIN) "Cannot use Orion with a deployment target lower than $(_THEOS_DARWIN_STABLE_SWIFT_VERSION) on the provided target platform." $(ERROR_END)
endif
endif
endif
	@for i in $(__USER_FILES); do \
		if [[ ! -f "$$i" ]]; then \
			$(PRINT_FORMAT_ERROR) "File $$i does not exist." $(ERROR_END) \
		fi; \
	done

ifeq ($(GO_EASY_ON_ME).$(DEBUG),1.0)
	@$(PRINT_FORMAT_WARNING) "GO_EASY_ON_ME quiets all errors, which is bad practice. Please migrate to Clang directives (e.g., -Wno-<blah> or #pragma clang diagnostic)." >&2
endif

after-$(THEOS_CURRENT_INSTANCE)-all::
	@:

internal-$(_THEOS_CURRENT_TYPE)-all:: before-$(THEOS_CURRENT_INSTANCE)-all internal-$(_THEOS_CURRENT_TYPE)-all_ after-$(THEOS_CURRENT_INSTANCE)-all
	@:

before-$(THEOS_CURRENT_INSTANCE)-stage after-$(THEOS_CURRENT_INSTANCE)-stage::
	@:

internal-$(_THEOS_CURRENT_TYPE)-stage:: before-$(THEOS_CURRENT_INSTANCE)-stage internal-$(_THEOS_CURRENT_TYPE)-stage_ after-$(THEOS_CURRENT_INSTANCE)-stage
	@:


.SUFFIXES:

.SUFFIXES: .m .mm .c .cc .cpp .xm .swift

MDFLAGS = -MP -MT "$@ $(subst .md,.o,$@)" -MM

ifeq ($(_THEOS_GENERATE_SWIFTMODULE_HEADER),$(_THEOS_TRUE))
# add swiftmodule header as dependency to all objc objects
$(patsubst %,$(THEOS_OBJ_DIR)/%.$(_THEOS_OBJ_FILE_TAG).o,$(OBJC_FILES)): $(_SWIFTMODULE_HEADER)
endif

$(THEOS_OBJ_DIR)/%.m.$(_THEOS_OBJ_FILE_TAG).o: %.m
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mi.$(_THEOS_OBJ_FILE_TAG).o: %.mi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c-cpp-output -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mm.$(_THEOS_OBJ_FILE_TAG).o: %.mm
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mii.$(_THEOS_OBJ_FILE_TAG).o: %.mii
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++-cpp-output -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c.$(_THEOS_OBJ_FILE_TAG).o: %.c
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.i.$(_THEOS_OBJ_FILE_TAG).o: %.i
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c-cpp-output -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.s.$(_THEOS_OBJ_FILE_TAG).o: %.s
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x assembler-with-cpp -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.S.$(_THEOS_OBJ_FILE_TAG).o: %.S
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x assembler-with-cpp -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cc.$(_THEOS_OBJ_FILE_TAG).o: %.cc
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cp.$(_THEOS_OBJ_FILE_TAG).o: %.cp
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cxx.$(_THEOS_OBJ_FILE_TAG).o: %.cxx
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.cpp.$(_THEOS_OBJ_FILE_TAG).o: %.cpp
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.c++.$(_THEOS_OBJ_FILE_TAG).o: %.c++
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++ -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.ii.$(_THEOS_OBJ_FILE_TAG).o: %.ii
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x c++-cpp-output -c $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(_ORION_GLUE): $(XSWIFT_FILES)
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING_XSWIFT)$(ECHO_UNBUFFERED)$(TARGET_ORION_BIN)/OrionCLI $(ALL_ORIONFLAGS) $(XSWIFT_FILES) -o $@$(ECHO_END)

# EASY PERFORMANCE WINS (TBD by somebody?):
# - Increasing num-threads during WMO builds might also help (see SWIFT_OPTFLAG in common.mk)

$(THEOS_OBJ_DIR)/output-file-map.$(_THEOS_OBJ_FILE_TAG).json: $(SWIFT_FILES)
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_NOTHING)$(TARGET_SWIFT_SUPPORT_BIN)/generate-output-file-map $(THEOS_OBJ_DIR) $(_THEOS_OBJ_FILE_TAG) $(SWIFT_FILES) > $@$(ECHO_END)

ifeq ($(THEOS_BUILD_SWIFT),$(_THEOS_TRUE))
ifeq ($(_THEOS_INTERNAL_USE_PARALLEL_BUILDING),$(_THEOS_TRUE))
MAKEFLAGS += -Onone
endif
internal-swift-$(THEOS_CURRENT_INSTANCE)-$(THEOS_CURRENT_ARCH):
	$(ECHO_NOTHING)$(TARGET_SWIFTC) -c $(_THEOS_INTERNAL_IFLAGS_SWIFT) $(ALL_SWIFTFLAGS) -target $(THEOS_CURRENT_ARCH)-$(_THEOS_TARGET_SWIFT_TARGET) -output-file-map $(THEOS_OBJ_DIR)/output-file-map.$(_THEOS_OBJ_FILE_TAG).json $(_THEOS_SWIFT_SWIFTMODULE_HEADER_FLAG) -emit-dependencies -emit-module-path $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE).swiftmodule -pch-output-dir $(THEOS_OBJ_DIR)/$(THEOS_CURRENT_INSTANCE)-pch $(SWIFT_FILES) -parseable-output 2>&1 \
	| $(TARGET_SWIFT_SUPPORT_BIN)/parse-swiftc-output $(or $(call __theos_bool,$(COLOR)),0) $(_THEOS_SWIFT_MUTEX) $(THEOS_CURRENT_ARCH)$(ECHO_END)
endif

# https://www.gnu.org/software/automake/manual/html_node/Multiple-Outputs.html
$(_SWIFT_STAMP): $(SWIFT_FILES) $(THEOS_OBJ_DIR)/output-file-map.$(_THEOS_OBJ_FILE_TAG).json
	$(ECHO_NOTHING)rm -f $@.tmp$(ECHO_END)
	$(ECHO_NOTHING)touch $@.tmp$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(foreach file,$(SWIFT_FILES),$(THEOS_OBJ_DIR)/$(dir $(file))) $(_THEOS_SWIFTMODULE_HEADER_DIR)$(ECHO_END)
	$(ECHO_NOTHING)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going \
		internal-swift-$(THEOS_CURRENT_INSTANCE)-$(THEOS_CURRENT_ARCH) \
		THEOS_BUILD_SWIFT="$(_THEOS_TRUE)" \
		THEOS_CURRENT_INSTANCE="$(THEOS_CURRENT_INSTANCE)" \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" \
		THEOS_CURRENT_ARCH="$(THEOS_CURRENT_ARCH)"$(ECHO_END)
	$(ECHO_NOTHING)mv -f $@.tmp $@$(ECHO_END)

$(_SWIFTMODULE_HEADER): $(_SWIFT_STAMP)
	@:

$(THEOS_OBJ_DIR)/%.swift.$(_THEOS_OBJ_FILE_TAG).o: $(_SWIFT_STAMP)
	@:

$(THEOS_OBJ_DIR)/%.x.m: %.x
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.x.$(_THEOS_OBJ_FILE_TAG).o: %.x $(THEOS_OBJ_DIR)/%.x.m
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -c -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(THEOS_OBJ_DIR)/$<.m -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.m$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xm.mm: %.xm
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xm.$(_THEOS_OBJ_FILE_TAG).o: %.xm $(THEOS_OBJ_DIR)/%.xm.mm
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -c -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(THEOS_OBJ_DIR)/$<.mm -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$<.mm$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mi: %.xi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -E -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_PFLAGS) $(PREPROCESS_ARCH_FLAGS) $(ALL_OBJCFLAGS) $< > $(THEOS_OBJ_DIR)/$<.pre && $(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $(THEOS_OBJ_DIR)/$<.pre > $(THEOS_OBJ_DIR)/$<.mi $(ECHO_END)
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xi.$(_THEOS_OBJ_FILE_TAG).o: %.xi $(THEOS_OBJ_DIR)/%.mi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(THEOS_OBJ_DIR)/$<.mi -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$*.mi$(ECHO_END)

$(THEOS_OBJ_DIR)/%.mii: %.xmi
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_PREPROCESSING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -E -I"$(call __clean_pwd,$(dir $<))" $(_THEOS_INTERNAL_IFLAGS_C) $(ALL_DEPFLAGS) $(ALL_PFLAGS) $(PREPROCESS_ARCH_FLAGS) $(ALL_OBJCFLAGS) $< > $(THEOS_OBJ_DIR)/$<.pre && $(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $(THEOS_OBJ_DIR)/$<.pre > $(THEOS_OBJ_DIR)/$<.mii $(ECHO_END)
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@$(ECHO_END)

$(THEOS_OBJ_DIR)/%.xmi.$(_THEOS_OBJ_FILE_TAG).o: %.xmi $(THEOS_OBJ_DIR)/%.mii
	$(ECHO_NOTHING)mkdir -p $(dir $@)$(ECHO_END)
	$(ECHO_COMPILING)$(ECHO_UNBUFFERED)$(TARGET_CXX) -x objective-c++ -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(THEOS_OBJ_DIR)/$<.mii -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(THEOS_OBJ_DIR)/$*.mii$(ECHO_END)

.PHONY: FORCE
FORCE:

define _THEOS_TEMPLATE_DEFAULT_LINKING_RULE
ifeq ($(TARGET_LIPO),)
ifneq ($$(_THEOS_CODESIGN_COMMANDLINE),)
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
ifeq ($$(_THEOS_CURRENT_TYPE),subproject)
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LIBTOOL) -static -o "$$@" $$^$$(ECHO_END)
else
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LD) $$(ALL_LDFLAGS) -o "$$@" $$^$$(ECHO_END)
ifneq ($$(TARGET_DSYMUTIL),)
	$$(ECHO_DEBUG_SYMBOLS)$$(ECHO_UNBUFFERED)$$(TARGET_DSYMUTIL) "$$@"$(ECHO_END)
endif
ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endif
else ifeq ($(THEOS_CURRENT_ARCH),)

ARCH_FILES_TO_LINK := $(addsuffix /$(1),$(addprefix $(THEOS_OBJ_DIR)/,$(TARGET_ARCHS)))
# It's critical that this always be run because otherwise if there are changes to
# files listed in the makedeps (*.Td) but this target just depends on __USER_FILES,
# Make won't reproduce the target
$$(THEOS_OBJ_DIR)/%/$(1): FORCE
	@mkdir -p $(THEOS_OBJ_DIR)/$$*
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going \
		internal-$(_THEOS_CURRENT_TYPE)-$(_THEOS_CURRENT_OPERATION) \
		_THEOS_CURRENT_TYPE="$(_THEOS_CURRENT_TYPE)" \
		THEOS_CURRENT_INSTANCE="$(THEOS_CURRENT_INSTANCE)" \
		_THEOS_CURRENT_OPERATION="$(_THEOS_CURRENT_OPERATION)" \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" \
		THEOS_CURRENT_ARCH="$$*"

ifneq ($$(_THEOS_CODESIGN_COMMANDLINE),)
.INTERMEDIATE: $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
$(THEOS_OBJ_DIR)/$(1): $$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned
	$$(ECHO_SIGNING)$$(_THEOS_CODESIGN_COMMANDLINE) "$$<" && mv "$$<" "$$@"$$(ECHO_END)
$(THEOS_OBJ_DIR)/$(1).$(_THEOS_OUT_FILE_TAG).unsigned: $$(ARCH_FILES_TO_LINK)
else
$(THEOS_OBJ_DIR)/$(1): $$(ARCH_FILES_TO_LINK)
endif
ifeq ($$(_THEOS_CURRENT_TYPE),subproject)
	@echo "$$(_THEOS_INTERNAL_LDFLAGS)" > $$(THEOS_OBJ_DIR)/$$(THEOS_CURRENT_INSTANCE).ldflags
endif
	$(ECHO_MERGING)$(ECHO_UNBUFFERED)$(TARGET_LIPO) $(foreach ARCH,$(TARGET_ARCHS),-arch $(ARCH) $(THEOS_OBJ_DIR)/$(ARCH)/$(1)) -create -output "$$@"$(ECHO_END)

else
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
	$$(ECHO_NOTHING)mkdir -p $(shell dirname "$(THEOS_OBJ_DIR)/$(1)")$$(ECHO_END)
ifeq ($$(_THEOS_CURRENT_TYPE),subproject)
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LIBTOOL) -static -o "$$@" $$^$$(ECHO_END)
	@echo "$$(_THEOS_INTERNAL_LDFLAGS)" > $$(THEOS_OBJ_DIR)/$$(THEOS_CURRENT_INSTANCE).ldflags
else
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LD) $$(ALL_LDFLAGS) -o "$$@" $$^$$(ECHO_END)
ifneq ($$(TARGET_DSYMUTIL),)
	$$(ECHO_DEBUG_SYMBOLS)$$(ECHO_UNBUFFERED)$$(TARGET_DSYMUTIL) "$$@"$(ECHO_END)
endif
ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endif
endif

endef

define _THEOS_TEMPLATE_ARCHIVE_LINKING_RULE
ifeq ($(TARGET_LIPO),)
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
ifeq ($$(_THEOS_CURRENT_TYPE),subproject)
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LIBTOOL) -static -o "$$@" $$^$$(ECHO_END)
else
	$$(ECHO_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LIBTOOL) -static -o "$$@" $$^$$(ECHO_END)
ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endif
else ifeq ($(THEOS_CURRENT_ARCH),)
ifeq ($(_THEOS_LIBRARY_TYPE),static)

ARCH_FILES_TO_LINK := $(addsuffix /$(1),$(addprefix $(THEOS_OBJ_DIR)/,$(TARGET_ARCHS)))
$$(THEOS_OBJ_DIR)/%/$(1): FORCE
	@mkdir -p $(THEOS_OBJ_DIR)/$$*
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going \
		internal-$(_THEOS_CURRENT_TYPE)-$(_THEOS_CURRENT_OPERATION) \
		_THEOS_CURRENT_TYPE="$(_THEOS_CURRENT_TYPE)" \
		THEOS_CURRENT_INSTANCE="$(THEOS_CURRENT_INSTANCE)" \
		_THEOS_CURRENT_OPERATION="$(_THEOS_CURRENT_OPERATION)" \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" \
		THEOS_CURRENT_ARCH="$$*"

endif
$(THEOS_OBJ_DIR)/$(1): $$(ARCH_FILES_TO_LINK)
ifeq ($$(_THEOS_CURRENT_TYPE),subproject)
	@echo "$$(_THEOS_INTERNAL_LDFLAGS)" > $$(THEOS_OBJ_DIR)/$$(THEOS_CURRENT_INSTANCE).ldflags
endif
	$(ECHO_MERGING)$(ECHO_UNBUFFERED)$(TARGET_LIPO) $(foreach ARCH,$(TARGET_ARCHS),-arch $(ARCH) $(THEOS_OBJ_DIR)/$(ARCH)/$(1)) -create -output "$$@"$(ECHO_END)

else
$$(THEOS_OBJ_DIR)/$(1): $$(OBJ_FILES_TO_LINK)
ifneq ($(2),nowarn)
ifeq ($$(OBJ_FILES_TO_LINK),)
	$$(WARNING_EMPTY_LINKING)
endif
endif
	$$(ECHO_NOTHING)mkdir -p $(shell dirname "$(THEOS_OBJ_DIR)/$(1)")$$(ECHO_END)
ifeq ($$(_THEOS_CURRENT_TYPE),subproject)
	$$(ECHO_STATIC_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LIBTOOL) -static -o "$$@" $$^$$(ECHO_END)
	@echo "$$(_THEOS_INTERNAL_LDFLAGS)" > $$(THEOS_OBJ_DIR)/$$(THEOS_CURRENT_INSTANCE).ldflags
else
	$$(ECHO_STATIC_LINKING)$$(ECHO_UNBUFFERED)$$(TARGET_LIBTOOL) -static -o "$$@" $$^$$(ECHO_END)
ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
ifeq ($$(_THEOS_IS_WSL),$(_THEOS_TRUE))
	mkdir -p "$$(_THEOS_TMP_FOR_WSL)/$$(THEOS_CURRENT_ARCH)"
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)cp "$$@" "$$(_THEOS_TMP_FOR_WSL)/$$(THEOS_CURRENT_ARCH)" && $$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$(_THEOS_TMP_FOR_WSL)/$$(THEOS_CURRENT_ARCH)/$(1)" && mv "$$(_THEOS_TMP_FOR_WSL)/$$(THEOS_CURRENT_ARCH)/$(1)" $$(THEOS_OBJ_DIR)$$(ECHO_END)
else
	$$(ECHO_STRIPPING)$$(ECHO_UNBUFFERED)$$(TARGET_STRIP) $$(ALL_STRIP_FLAGS) "$$@"$$(ECHO_END)
endif
endif
endif
endif

endef

$(eval $(call __mod,instance/rules.mk))
