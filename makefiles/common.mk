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
_THEOS_LOCAL_DATA_DIR := $(THEOS_PROJECT_DIR)/$(_THEOS_RELATIVE_DATA_DIR)
_THEOS_BUILD_SESSION_FILE = $(_THEOS_LOCAL_DATA_DIR)/build_session

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

empty :=
space := $(empty) $(empty)

define __cmp
$(if $(filter $(1),$(2)),eq,$(strip \
 $(eval __CMP_NUM1:=$(subst 0,0 ,$(subst 1,1 ,$(subst 2,2 ,$(subst 3,3 ,$(subst 4,4 ,$(subst 5,5 ,$(subst 6,6 ,$(subst 7,7 ,$(subst 8,8 ,$(subst 9,9 ,$(1)))))))))))) \
 $(eval __CMP_NUM2:=$(subst 0,0 ,$(subst 1,1 ,$(subst 2,2 ,$(subst 3,3 ,$(subst 4,4 ,$(subst 5,5 ,$(subst 6,6 ,$(subst 7,7 ,$(subst 8,8 ,$(subst 9,9 ,$(2)))))))))))) \
 $(if $(filter-out 1,$(words $(__CMP_NUM1)))$(filter-out 1,$(words $(__CMP_NUM2))),$(strip \
   $(call __vercmp_expand_backward,__CMP_NUM1,$(__CMP_NUM1),$(__CMP_NUM2)) \
   $(call __vercmp_expand_backward,__CMP_NUM2,$(__CMP_NUM2),$(__CMP_NUM1)) \
   $(eval __CMP_RES:=eq) \
   $(call __vercmp_presplit,__CMP_NUM1,__CMP_NUM2,__CMP_RES) \
   ),$(if $(filter $(1),$(firstword $(sort $(1) $(2)))),lt,gt) \
  ) \
))
endef

define __vercmp
$(strip \
$(eval VERCMP_FIRST := $(subst .,$(space),$(1))) \
$(eval VERCMP_OP := $(if $(filter ge,$(2)),eq gt,$(if $(filter le,$(2)),eq lt,$(2)))) \
$(eval VERCMP_SECOND := $(subst .,$(space),$(3))) \
$(eval VERCMP_RES := eq) \
$(call __vercmp_expand,VERCMP_FIRST,$(VERCMP_FIRST),$(VERCMP_SECOND)) \
$(call __vercmp_expand,VERCMP_SECOND,$(VERCMP_SECOND),$(VERCMP_FIRST)) \
$(if $(filter $(VERCMP_OP),$(call __vercmp_presplit,VERCMP_FIRST,VERCMP_SECOND,VERCMP_RES)),1,) \
)
endef

define __vercmp_presplit
$(strip \
 $(foreach ver1,$(value $(1)),$(if $(filter eq,$(value $(3))), \
  $(eval $(3):=$(call __cmp,$(ver1),$(firstword $(value $(2)))$(eval $(2):=$(wordlist 2,$(words $(value $(2))),$(value $(2)))))) \
 ,)) \
 $(value $(3)) \
)
endef

define __vercmp_expand
$(if $(filter $(words $(2)),$(words $(3))),, \
$(if $(filter $(words $(3)),$(firstword $(sort $(words $(2)) $(words $(3))))),, \
$(eval $(1) += 0) \
$(call __vercmp_expand,$(1),$(value $(1)),$(3)) \
) \
)
endef

define __vercmp_expand_backward
$(if $(filter $(words $(2)),$(words $(3))),, \
$(if $(filter $(words $(3)),$(firstword $(sort $(words $(2)) $(words $(3))))),, \
$(eval $(1) := 0 $(1)) \
$(call __vercmp_expand_backward,$(1),$(value $(1)),$(3)) \
) \
)
endef

define __vercmp_expand_first
$(if $(filter $(words $(VERCMP_FIRST)),$(words $(VERCMP_SECOND))),, \
$(if $(filter $(words $(VERCMP_SECOND)),$(firstword $(sort $(words $(VERCMP_FIRST)) $(words $(VERCMP_SECOND))))),, \
$(eval VERCMP_FIRST += 0) \
$(call __vercmp_expand_first) \
) \
)
endef

define __vercmp_expand_second
$(if $(filter $(words $(VERCMP_FIRST)),$(words $(VERCMP_SECOND))),, \
$(if $(filter $(words $(VERCMP_FIRST)),$(firstword $(sort $(words $(VERCMP_FIRST)) $(words $(VERCMP_SECOND))))),, \
$(eval VERCMP_SECOND += 0) \
$(call __vercmp_expand_second) \
) \
)
endef

ifeq (0,1)
# __vercmp test code
$(info 1.8,gt,1.7: $(call __vercmp,1.8,gt,1.7))
$(info 1.7,gt,1.8: $(call __vercmp,1.7,gt,1.8))
$(info 1.8,eq,1.8: $(call __vercmp,1.8,eq,1.8))
$(info 1.8,eq,1.7: $(call __vercmp,1.8,eq,1.7))
$(info 1.8,lt,1.9: $(call __vercmp,1.8,lt,1.9))
$(info 1.8,lt,1.10: $(call __vercmp,1.8,lt,1.10))
$(info 5.0,ge,5.0.1: $(call __vercmp,5.0,ge,5.0.1))
$(info 5.0.1,ge,5.0: $(call __vercmp,5.0.1,ge,5.0))
$(info 5.0,ge,5.0: $(call __vercmp,5.0.1,ge,5.0))
$(info 5.0,le,5.0.1: $(call __vercmp,5.0,le,5.0.1))
$(info 5.0,le,5.0: $(call __vercmp,5.0,le,5.0))
$(info 5.0,le,4.9: $(call __vercmp,5.0.1,le,4.9))
endif

__THEOS_COMMON_MK_VERSION := 1k

ifneq ($(words $(THEOS_PROJECT_DIR)),1)
$(error Your project is located at “$(THEOS_PROJECT_DIR)”, which contains spaces. Spaces are not supported in the project path)
endif

ifeq ($(_THEOS_PROJECT_MAKEFILE_NAME),)
_THEOS_STATIC_MAKEFILE_LIST := $(filter-out $(lastword $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
export _THEOS_PROJECT_MAKEFILE_NAME := $(notdir $(lastword $(_THEOS_STATIC_MAKEFILE_LIST)))
endif

ifeq ($(_THEOS_INTERNAL_TRUE_PATH),)
_THEOS_RELATIVE_MAKE_PATH := $(dir $(lastword $(MAKEFILE_LIST)))
_THEOS_INTERNAL_TRUE_PATH := $(call __clean_pwd,$(_THEOS_RELATIVE_MAKE_PATH)/..)
ifneq ($(words $(_THEOS_INTERNAL_TRUE_PATH)),1) # It's a hack, but it works.
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
THEOS_MODULE_PATH := $(THEOS)/mod
THEOS_SDKS_PATH := $(THEOS)/sdks
export THEOS THEOS_BIN_PATH THEOS_MAKE_PATH THEOS_LIBRARY_PATH THEOS_VENDOR_LIBRARY_PATH THEOS_INCLUDE_PATH THEOS_VENDOR_INCLUDE_PATH THEOS_FALLBACK_INCLUDE_PATH
export THEOS_PROJECT_DIR

export PATH := $(THEOS_BIN_PATH):$(PATH)

ifeq ($(call __exists,$(HOME)/.theosrc),$(_THEOS_TRUE))
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

THEOS_LAYOUT_DIR_NAME ?= layout
THEOS_LAYOUT_DIR ?= $(THEOS_PROJECT_DIR)/$(THEOS_LAYOUT_DIR_NAME)
ifeq ($(_THEOS_HAS_STAGING_LAYOUT),)
_THEOS_HAS_STAGING_LAYOUT := $(call __exists,$(THEOS_LAYOUT_DIR))
endif

_THEOS_LOAD_MODULES := $(sort $(call __schema_var_all,,MODULES) $(THEOS_AUTOLOAD_MODULES))
__mod = -include $$(foreach mod,$$(_THEOS_LOAD_MODULES),$$(THEOS_MODULE_PATH)/$$(mod)/$(1))

include $(THEOS_MAKE_PATH)/legacy.mk

ifneq ($(_THEOS_PLATFORM_CALCULATED),1)
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

ifneq ($(_THEOS_TARGET_CALCULATED),1)
__TARGET_MAKEFILE := $(shell $(THEOS_BIN_PATH)/target.pl "$(target)" "$(call __schema_var_last,,TARGET)" "$(_THEOS_PLATFORM_DEFAULT_TARGET)")
-include $(__TARGET_MAKEFILE)
$(shell rm -f $(__TARGET_MAKEFILE) > /dev/null 2>&1)
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

ifneq ($(_THEOS_TARGET_LOADED),1)
$(error The "$(_THEOS_TARGET)" target is not supported on the "$(THEOS_PLATFORM_NAME)" platform)
endif

_THEOS_TARGET_NAME_DEFINE := $(shell echo "$(THEOS_TARGET_NAME)" | tr 'a-z' 'A-Z')

export TARGET_CC TARGET_CXX TARGET_LD TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS

THEOS_TARGET_INCLUDE_PATH := $(THEOS_INCLUDE_PATH)/$(THEOS_TARGET_NAME)
THEOS_TARGET_LIBRARY_PATH := $(THEOS_LIBRARY_PATH)/$(THEOS_TARGET_NAME)
_THEOS_TARGET_HAS_INCLUDE_PATH := $(call __exists,$(THEOS_TARGET_INCLUDE_PATH))
_THEOS_TARGET_HAS_LIBRARY_PATH := $(call __exists,$(THEOS_TARGET_LIBRARY_PATH))

# Package Format requires Target default and falls back to `none'.
_THEOS_PACKAGE_FORMAT := $(or $(call __schema_var_last,,$(_THEOS_TARGET_NAME_DEFINE)_PACKAGE_FORMAT),$(call __schema_var_last,,PACKAGE_FORMAT),$(_THEOS_TARGET_DEFAULT_PACKAGE_FORMAT),none)
_THEOS_PACKAGE_LAST_FILENAME = $(call __simplify,_THEOS_PACKAGE_LAST_FILENAME,$(shell cat "$(_THEOS_LOCAL_DATA_DIR)/last_package" 2>/dev/null))

# ObjC/++ stuff is not here, it's in instance/rules.mk and only added if there are OBJC/OBJCC objects.
_THEOS_INTERNAL_LDFLAGS = $(if $(_THEOS_TARGET_HAS_LIBRARY_PATH),-L$(THEOS_TARGET_LIBRARY_PATH) )-L$(THEOS_LIBRARY_PATH) $(DEBUGFLAG)
ifneq ($(THEOS_VENDOR_LIBRARY_PATH),)
_THEOS_INTERNAL_LDFLAGS += -L$(THEOS_VENDOR_LIBRARY_PATH)
endif

DEBUGFLAG ?= -ggdb
SWIFT_DEBUGFLAG ?= -g
DEBUG.CFLAGS = -DDEBUG -O0
DEBUG.SWIFTFLAGS = -DDEBUG -Onone
DEBUG.LDFLAGS = -O0

_THEOS_SHOULD_STRIP_DEFAULT := $(_THEOS_TRUE)

ifneq ($(findstring DEBUG,$(THEOS_SCHEMA)),)
_THEOS_SHOULD_STRIP_DEFAULT := $(_THEOS_FALSE)
PACKAGE_BUILDNAME ?= debug
endif

SHOULD_STRIP := $(call __theos_bool,$(or $(strip),$(STRIP),$(_THEOS_SHOULD_STRIP_DEFAULT)))

ifeq ($(SHOULD_STRIP),$(_THEOS_TRUE))
OPTFLAG ?= -Os
SWIFT_OPTFLAG ?= -O -whole-module-optimization
else
TARGET_STRIP = :
OPTFLAG ?= -O0
endif

_THEOS_INTERNAL_CFLAGS = -DTARGET_$(_THEOS_TARGET_NAME_DEFINE)=1 $(OPTFLAG) -Wall $(DEBUGFLAG)
_THEOS_INTERNAL_SWIFTFLAGS = -DTHEOS_SWIFT -DTARGET_$(_THEOS_TARGET_NAME_DEFINE) $(SWIFT_OPTFLAG) -module-name $(THEOS_CURRENT_INSTANCE) $(SWIFT_DEBUGFLAG)
_THEOS_INTERNAL_IFLAGS_BASE = $(if $(_THEOS_TARGET_HAS_INCLUDE_PATH),-I$(THEOS_TARGET_INCLUDE_PATH) )-I$(THEOS_INCLUDE_PATH) -I$(THEOS_VENDOR_INCLUDE_PATH) -I$(THEOS_FALLBACK_INCLUDE_PATH)
_THEOS_INTERNAL_IFLAGS_C = $(_THEOS_INTERNAL_IFLAGS_BASE) -include $(THEOS)/Prefix.pch
_THEOS_INTERNAL_IFLAGS_SWIFT = $(_THEOS_INTERNAL_IFLAGS_BASE)

ifneq ($(GO_EASY_ON_ME),1)
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
	_THEOS_INTERNAL_SWIFTCOLORFLAGS += -color-diagnostics
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
_SPACE := $(subst x,,x x)
_THEOS_ESCAPED_STAGING_DIR = $(subst $(_SPACE),\ ,$(THEOS_STAGING_DIR))

THEOS_PACKAGE_DIR_NAME ?= packages
THEOS_PACKAGE_DIR ?= $(THEOS_BUILD_DIR)/$(THEOS_PACKAGE_DIR_NAME)
THEOS_LEGACY_PACKAGE_DIR = $(THEOS_BUILD_DIR)/debs

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
THEOS_PACKAGE_VERSION = $(call __simplify,THEOS_PACKAGE_VERSION,$(THEOS_PACKAGE_BASE_VERSION)$(warning THEOS_PACKAGE_VERSION is deprecated. Please migrate to THEOS_PACKAGE_BASE_VERSION.))

THEOS_LINKAGE_TYPE ?= dynamic

$(eval $(call __mod,common.mk))
