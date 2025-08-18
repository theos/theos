all::

# common.mk should only be included once. Throw an error if already included in this makefile.
ifneq ($(__THEOS_COMMON_MK_VERSION),)
$(error common.mk has been included multiple times. Please check your makefiles)
endif

# Block sudo. This is a common way users create more permissions problems than they already had.
ifeq ($(notdir $(firstword $(SUDO_COMMAND))),make)
$(error Do not use 'sudo make')
endif

# We use bash for all subshells. Force SHELL to bash if it’s currently set to sh.
ifeq ($(SHELL),/bin/sh)
export SHELL = bash
endif

ifeq ($(THEOS_PROJECT_DIR),)
THEOS_PROJECT_DIR := $(shell pwd)
endif
_THEOS_RELATIVE_DATA_DIR ?= .theos
_THEOS_LOCAL_DATA_DIR ?= $(THEOS_PROJECT_DIR)/$(_THEOS_RELATIVE_DATA_DIR)
_THEOS_BUILD_SESSION_FILE = $(_THEOS_LOCAL_DATA_DIR)/build_session
_THEOS_SPM_CONFIG_FILE := $(_THEOS_LOCAL_DATA_DIR)/spm_config
_THEOS_COMPILE_COMMANDS_FILE := $(THEOS_PROJECT_DIR)/compile_commands.json
_THEOS_TMP_COMPILE_COMMANDS_FILE := $(_THEOS_LOCAL_DATA_DIR)/compile_commands.json.tmp

### Functions
# Function for getting a clean absolute path from cd.
__clean_pwd = $(shell (unset CDPATH; cd "$(1)"; pwd))
# Truthiness
_THEOS_TRUE := 1
_THEOS_FALSE :=
__theos_bool = $(if $(filter Y y YES yes TRUE true 1,$(1)),$(_THEOS_TRUE),$(_THEOS_FALSE))
# Existence
__exists = $(if $(wildcard $(1)),$(_THEOS_TRUE),$(_THEOS_FALSE))
__executable = $(if $(shell PATH="$(THEOS_BIN_PATH):$$PATH" type "$(1)" > /dev/null 2>&1 && echo 1),$(_THEOS_TRUE),$(_THEOS_FALSE))
# Static redefinition
__simplify = $(2)$(eval $(1):=$(2))
###

__THEOS_COMMON_MK_VERSION := 1k

ifneq ($(words $(THEOS_PROJECT_DIR)),1)
$(error Your project is located at “$(THEOS_PROJECT_DIR)”, which contains spaces. Spaces are not supported in the project path)
endif

ifeq ($(_THEOS_PROJECT_MAKEFILE_NAME),)
_THEOS_STATIC_MAKEFILE_LIST := $(filter-out $(lastword $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
export _THEOS_PROJECT_MAKEFILE_NAME := $(notdir $(firstword $(_THEOS_STATIC_MAKEFILE_LIST)))
endif

ifeq ($(_THEOS_INTERNAL_TRUE_PATH),)
_THEOS_RELATIVE_MAKE_PATH := $(dir $(lastword $(MAKEFILE_LIST)))
_THEOS_INTERNAL_TRUE_PATH := $(call __clean_pwd,$(_THEOS_RELATIVE_MAKE_PATH)/..)
ifneq ($(words $(_THEOS_INTERNAL_TRUE_PATH)),1) # It’s a hack, but it works.
$(shell unlink /tmp/theos &> /dev/null; ln -Ffs "$(_THEOS_INTERNAL_TRUE_PATH)" /tmp/theos)
_THEOS_INTERNAL_TRUE_PATH := /tmp/theos
endif
override THEOS := $(_THEOS_INTERNAL_TRUE_PATH)
export _THEOS_INTERNAL_TRUE_PATH
endif
THEOS_MAKE_PATH := $(THEOS)/makefiles
THEOS_BIN_PATH := $(THEOS)/bin
THEOS_LIBRARY_PATH := $(THEOS)/lib
THEOS_VENDOR_LIBRARY_PATH := $(THEOS)/vendor/lib
THEOS_INCLUDE_PATH := $(THEOS)/include
THEOS_VENDOR_INCLUDE_PATH := $(THEOS)/vendor/include
THEOS_FALLBACK_INCLUDE_PATH := $(THEOS)/include/_fallback
THEOS_VENDOR_SWIFT_SUPPORT_PATH := $(THEOS)/vendor/swift-support
THEOS_VENDOR_ORION_PATH := $(THEOS)/vendor/orion
THEOS_MODULE_PATH := $(THEOS)/mod
THEOS_VENDOR_MODULE_PATH := $(THEOS)/vendor/mod
THEOS_SDKS_PATH := $(THEOS)/sdks
export THEOS THEOS_BIN_PATH THEOS_MAKE_PATH THEOS_LIBRARY_PATH THEOS_VENDOR_LIBRARY_PATH THEOS_INCLUDE_PATH THEOS_VENDOR_INCLUDE_PATH THEOS_FALLBACK_INCLUDE_PATH
export THEOS_PROJECT_DIR

export PATH := $(THEOS_BIN_PATH):$(PATH)

ifeq ($(call __exists,$(XDG_CONFIG_HOME)/theos/rc.mk),$(_THEOS_TRUE))
-include $(XDG_CONFIG_HOME)/theos/rc.mk
else ifeq ($(call __exists,$(HOME)/.config/theos/rc.mk),$(_THEOS_TRUE))
-include $(HOME)/.config/theos/rc.mk
else ifeq ($(call __exists,$(HOME)/.theosrc),$(_THEOS_TRUE))
-include $(HOME)/.theosrc
endif

_THEOS_FINAL_PACKAGE := $(_THEOS_FALSE)

ifeq ($(call __theos_bool,$(or $(FOR_RELEASE),$(FINALPACKAGE))),$(_THEOS_TRUE))
_THEOS_FINAL_PACKAGE := $(_THEOS_TRUE)
endif

ifeq ($(THEOS_SCHEMA),)
_THEOS_SCHEMA := $(shell echo "$(strip $(schema) $(SCHEMA))" | tr 'a-z' 'A-Z')
_THEOS_ON_SCHEMA := DEFAULT $(filter-out -%,$(_THEOS_SCHEMA))
ifeq ($(or $(debug),$(DEBUG))$(_THEOS_FINAL_PACKAGE),$(_THEOS_FALSE))
	DEBUG := 1
endif
ifeq ($(call __theos_bool,$(or $(debug),$(DEBUG))),$(_THEOS_TRUE))
	_THEOS_ON_SCHEMA += DEBUG
endif
_THEOS_OFF_SCHEMA := $(patsubst -%,%,$(filter -%,$(_THEOS_SCHEMA)))
override THEOS_SCHEMA := $(strip $(filter-out $(_THEOS_OFF_SCHEMA),$(_THEOS_ON_SCHEMA)))
override _THEOS_CLEANED_SCHEMA_SET := $(shell echo "$(filter-out DEFAULT,$(THEOS_SCHEMA))" | tr -Cd ' A-Z' | tr ' A-Z' '_a-z')
export THEOS_SCHEMA _THEOS_CLEANED_SCHEMA_SET
endif

###
# __schema_defined_var_names bears explanation:
# For each schema'd variable gathered from __schema_all_var_names, we generate a list of
# "origin:name" pairs, and then filter out all pairs where the origin is "undefined".
# We then substitute " " for ":" and take the last word, so we end up with only the entries from
# __schema_all_var_names that are defined.
__schema_all_var_names = $(foreach sch,$(THEOS_SCHEMA),$(subst DEFAULT.,,$(sch).)$(1)$(2))
__schema_defined_var_names = $(foreach tuple,$(filter-out undefined:%,$(foreach schvar,$(call __schema_all_var_names,$(1),$(2)),$(origin $(schvar)):$(schvar))),$(lastword $(subst :, ,$(tuple))))
__schema_var_all = $(strip $(foreach sch,$(call __schema_all_var_names,$(1),$(2)),$($(sch))))
__schema_var_name_last = $(strip $(lastword $(call __schema_defined_var_names,$(1),$(2))))
__schema_var_last = $(strip $($(lastword $(call __schema_defined_var_names,$(1),$(2)))))

include $(THEOS_MAKE_PATH)/vercmp.mk
include $(THEOS_MAKE_PATH)/target.mk

THEOS_LAYOUT_DIR_NAME ?= layout
THEOS_LAYOUT_DIR ?= $(THEOS_PROJECT_DIR)/$(THEOS_LAYOUT_DIR_NAME)
ifeq ($(_THEOS_HAS_STAGING_LAYOUT),)
_THEOS_HAS_STAGING_LAYOUT := $(call __exists,$(THEOS_LAYOUT_DIR))
endif

_THEOS_LOAD_MODULES := $(sort $(call __schema_var_all,,MODULES) $(THEOS_AUTOLOAD_MODULES))
ifneq ($(THEOS_PACKAGE_SCHEME),)
_THEOS_LOAD_MODULES += $(or $(notdir $(wildcard $(THEOS_VENDOR_MODULE_PATH)/$(THEOS_PACKAGE_SCHEME))), \
				$(notdir $(wildcard $(THEOS_MODULE_PATH)/$(THEOS_PACKAGE_SCHEME))), \
				$(error '$(THEOS_PACKAGE_SCHEME)' package scheme does not exist))
endif
__mod = -include $$(foreach mod,$$(_THEOS_LOAD_MODULES),$$(or $$(wildcard $$(THEOS_VENDOR_MODULE_PATH)/$$(mod)/$(1)),$$(wildcard $$(THEOS_MODULE_PATH)/$$(mod)/$(1))))

include $(THEOS_MAKE_PATH)/legacy.mk

ifneq ($(_THEOS_PLATFORM_CALCULATED),$(_THEOS_TRUE))
uname_s := $(shell uname -s)
uname_o := $(shell uname -o 2>/dev/null)

export _THEOS_PLATFORM = $(uname_s)
export _THEOS_OS = $(if $(uname_o),$(uname_o),$(uname_s))
export _THEOS_PLATFORM_CALCULATED := 1
endif

-include $(THEOS_MAKE_PATH)/platform/$(_THEOS_PLATFORM).mk
-include $(THEOS_MAKE_PATH)/platform/$(_THEOS_OS).mk
$(eval $(call __mod,platform/$(_THEOS_PLATFORM).mk))
$(eval $(call __mod,platform/$(_THEOS_OS).mk))

ifneq ($(_THEOS_TARGET_CALCULATED),$(_THEOS_TRUE))
$(call __eval_target,$(target),$(call __schema_var_last,,TARGET),$(_THEOS_PLATFORM_DEFAULT_TARGET))
export _THEOS_TARGET := $(__THEOS_TARGET_ARG_0)
ifeq ($(_THEOS_TARGET),)
$(error You did not specify a target, and the "$(THEOS_PLATFORM_NAME)" platform does not define a default target)
endif
_THEOS_TARGET_CALCULATED := 1
endif

-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_PLATFORM)/$(_THEOS_TARGET).mk
-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_OS)/$(_THEOS_TARGET).mk
-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_TARGET).mk
$(eval $(call __mod,targets/$(_THEOS_PLATFORM)/$(_THEOS_TARGET).mk))
$(eval $(call __mod,targets/$(_THEOS_OS)/$(_THEOS_TARGET).mk))
$(eval $(call __mod,targets/$(_THEOS_TARGET).mk))

ifneq ($(_THEOS_TARGET_LOADED),$(_THEOS_TRUE))
$(error The "$(_THEOS_TARGET)" target is not supported on the "$(THEOS_PLATFORM_NAME)" platform)
endif

_THEOS_TARGET_NAME_DEFINE := $(shell echo "$(THEOS_TARGET_NAME)" | tr 'a-z' 'A-Z')

export TARGET_CC TARGET_CXX TARGET_LD TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS

THEOS_TARGET_INCLUDE_PATH := $(THEOS_INCLUDE_PATH)/$(THEOS_TARGET_NAME)
THEOS_TARGET_LIBRARY_PATH := $(THEOS_LIBRARY_PATH)/$(THEOS_TARGET_NAME)

# Package Format requires Target default and falls back to `none'.
_THEOS_PACKAGE_FORMAT := $(or $(call __schema_var_last,,$(_THEOS_TARGET_NAME_DEFINE)_PACKAGE_FORMAT),$(call __schema_var_last,,PACKAGE_FORMAT),$(_THEOS_TARGET_DEFAULT_PACKAGE_FORMAT),none)
_THEOS_PACKAGE_LAST_FILENAME = $(call __simplify,_THEOS_PACKAGE_LAST_FILENAME,$(shell cat "$(_THEOS_LOCAL_DATA_DIR)/last_package" 2>/dev/null))

_THEOS_INTERNAL_SEARCHPATHS := $(TARGET_PRIVATE_FRAMEWORK_PATH)
ifeq ($(THEOS_PACKAGE_SCHEME),)
_THEOS_INTERNAL_SEARCHPATHS += \
	$(THEOS_VENDOR_LIBRARY_PATH) \
	$(THEOS_LIBRARY_PATH) \
	$(THEOS_TARGET_LIBRARY_PATH)
else
_THEOS_INTERNAL_SEARCHPATHS += \
	$(THEOS_VENDOR_LIBRARY_PATH)/$(THEOS_TARGET_NAME)/$(THEOS_PACKAGE_SCHEME) \
	$(THEOS_LIBRARY_PATH)/$(THEOS_TARGET_NAME)/$(THEOS_PACKAGE_SCHEME)
endif
_THEOS_INTERNAL_LDFLAGS = $(foreach path,$(_THEOS_INTERNAL_SEARCHPATHS),$(if $(call __exists,$(path)),-L$(path) -F$(path))) $(DEBUGFLAG)

DEBUGFLAG ?= -ggdb
SWIFT_DEBUGFLAG ?= -g
DEBUG.CFLAGS = -DDEBUG -O0
DEBUG.SWIFTFLAGS = -DDEBUG -Onone -incremental
DEBUG.LDFLAGS = -O0

_THEOS_SHOULD_STRIP_DEFAULT := $(_THEOS_TRUE)

ifneq ($(findstring DEBUG,$(THEOS_SCHEMA)),)
_THEOS_SHOULD_STRIP_DEFAULT := $(_THEOS_FALSE)
PACKAGE_BUILDNAME ?= debug
endif

SHOULD_STRIP := $(call __theos_bool,$(or $(strip),$(STRIP),$(_THEOS_SHOULD_STRIP_DEFAULT)))

ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
OPTFLAG ?= -Os
SWIFT_OPTFLAG ?= -O -whole-module-optimization -num-threads 1
else
TARGET_STRIP = :
OPTFLAG ?= -O0
endif

THEOS_INCLUDE_PROJECT_DIR ?= yes

_THEOS_INTERNAL_CFLAGS = -DTARGET_$(_THEOS_TARGET_NAME_DEFINE)=1 $(OPTFLAG) -Wall $(DEBUGFLAG) -Wno-unused-command-line-argument -Qunused-arguments $(foreach path,$(_THEOS_INTERNAL_SEARCHPATHS),-F$(path))
_THEOS_INTERNAL_SWIFTFLAGS = -DTHEOS_SWIFT -DTARGET_$(_THEOS_TARGET_NAME_DEFINE) $(SWIFT_OPTFLAG) -module-name $(THEOS_CURRENT_INSTANCE) $(SWIFT_DEBUGFLAG) $(foreach path,$(_THEOS_INTERNAL_SEARCHPATHS),-F$(path))
_THEOS_INTERNAL_IFLAGS_BASE = -I$(THEOS_TARGET_INCLUDE_PATH) -I$(THEOS_INCLUDE_PATH) -I$(THEOS_VENDOR_INCLUDE_PATH) -I$(THEOS_FALLBACK_INCLUDE_PATH)
_THEOS_INTERNAL_IFLAGS_C = $(_THEOS_INTERNAL_IFLAGS_BASE) -include $(THEOS)/Prefix.pch $(if $(call __theos_bool,$(THEOS_INCLUDE_PROJECT_DIR)),-iquote $(THEOS_PROJECT_DIR))
_THEOS_INTERNAL_IFLAGS_SWIFT = $(_THEOS_INTERNAL_IFLAGS_BASE)

ifneq ($(GO_EASY_ON_ME),$(_THEOS_TRUE))
	_THEOS_INTERNAL_LOGOSFLAGS += -c warnings=error
	_THEOS_INTERNAL_CFLAGS += -Werror
endif

# If COLOR hasn’t already been set, set it to enabled. We need to do this because output is buffered
# by make when running rules in parallel, so clang doesn’t see stderr as a tty. We can’t test this
# using [ -t 2 ] because it runs in a sub-shell and will always return 1 (false).
COLOR ?= $(_THEOS_TRUE)

ifeq ($(call __theos_bool,$(or $(COLOR),$(FORCE_COLOR))),$(_THEOS_TRUE))
	COLOR := $(_THEOS_TRUE)
	_THEOS_INTERNAL_COLORFLAGS += -fcolor-diagnostics
	_THEOS_INTERNAL_SWIFTCOLORFLAGS += -Xfrontend -color-diagnostics
endif

THEOS_BUILD_DIR ?= .

ifneq ($(_THEOS_CLEANED_SCHEMA_SET),)
	_THEOS_OBJ_DIR_EXTENSION = /$(_THEOS_CLEANED_SCHEMA_SET)
endif
ifneq ($(THEOS_TARGET_NAME),$(_THEOS_PLATFORM_DEFAULT_TARGET))
	THEOS_OBJ_DIR_NAME ?= obj/$(THEOS_TARGET_NAME)$(_THEOS_OBJ_DIR_EXTENSION)
else
	THEOS_OBJ_DIR_NAME ?= obj$(_THEOS_OBJ_DIR_EXTENSION)
endif
ifeq ($(THEOS_CURRENT_ARCH),)
THEOS_OBJ_DIR = $(_THEOS_LOCAL_DATA_DIR)/$(THEOS_OBJ_DIR_NAME)
else
THEOS_OBJ_DIR = $(_THEOS_LOCAL_DATA_DIR)/$(THEOS_OBJ_DIR_NAME)/$(THEOS_CURRENT_ARCH)
endif

THEOS_STAGING_DIR_NAME ?= _
THEOS_STAGING_DIR ?= $(_THEOS_LOCAL_DATA_DIR)/$(THEOS_STAGING_DIR_NAME)
_THEOS_STAGING_TMP = $(THEOS_STAGING_DIR)tmp
_THEOS_SCHEME_STAGE = $(_THEOS_STAGING_TMP)$(THEOS_PACKAGE_INSTALL_PREFIX)
_SPACE := $(subst x,,x x)
_COMMA := ,

THEOS_PACKAGE_DIR_NAME ?= packages
THEOS_PACKAGE_DIR ?= $(THEOS_BUILD_DIR)/$(THEOS_PACKAGE_DIR_NAME)

THEOS_SUBPROJECT_PRODUCT = subproject.a

include $(THEOS_MAKE_PATH)/messages.mk

_THEOS_MAKEFLAGS := --no-keep-going COLOR=$(COLOR)

ifeq ($(_THEOS_VERBOSE),$(_THEOS_FALSE))
	_THEOS_MAKEFLAGS += --no-print-directory
endif
MAKEFLAGS += $(_THEOS_MAKEFLAGS)

unexport THEOS_CURRENT_INSTANCE _THEOS_CURRENT_TYPE

THEOS_RSYNC_EXCLUDES ?= _MTN .git .svn .DS_Store ._*
_THEOS_RSYNC_EXCLUDE_COMMANDLINE := $(foreach exclude,$(THEOS_RSYNC_EXCLUDES),--exclude "$(exclude)")

FAKEROOT := $(THEOS_BIN_PATH)/fakeroot.sh -p "$(_THEOS_LOCAL_DATA_DIR)/fakeroot"
export FAKEROOT

_THEOS_MAKE_PARALLEL_BUILDING ?= yes

ifeq ($(THEOS_CURRENT_INSTANCE),)
	include $(THEOS_MAKE_PATH)/stage.mk
	include $(THEOS_MAKE_PATH)/package.mk
endif

THEOS_LINKAGE_TYPE ?= dynamic

$(eval $(call __mod,common.mk))
