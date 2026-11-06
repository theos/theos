ifeq ($(_THEOS_PLATFORM_LOADED),)
_THEOS_PLATFORM_LOADED := 1
THEOS_PLATFORM_NAME := windows

_THEOS_PLATFORM_DEFAULT_TARGET := iphone
_THEOS_PLATFORM_DU_EXCLUDE := --exclude
_THEOS_PLATFORM_SHOW_IN_FILE_MANAGER := explorer /select,
_THEOS_PLATFORM_SHOW_IN_FILE_MANAGER_PATH_TRANSLATOR :=
_THEOS_PLATFORM_GET_LOGICAL_CORES := powershell.exe -NoProfile -Command "[Environment]::ProcessorCount"
_THEOS_WINDOWS_PYTHON ?= python
_THEOS_WINDOWS_HELPER := $(_THEOS_WINDOWS_PYTHON) "$(THEOS_BIN_PATH)/theos-windows.py"
_THEOS_MKDIR = $(_THEOS_WINDOWS_HELPER) mkdir
_THEOS_RM = $(_THEOS_WINDOWS_HELPER) rm
_THEOS_TOUCH = $(_THEOS_WINDOWS_HELPER) touch
_THEOS_CP = $(_THEOS_WINDOWS_HELPER) copy
_THEOS_MV = $(_THEOS_WINDOWS_HELPER) move
_THEOS_READ = $(_THEOS_WINDOWS_HELPER) read
_THEOS_CONTROL_FIELD = $(_THEOS_WINDOWS_HELPER) control-field
_THEOS_INSTALLED_SIZE = $(_THEOS_WINDOWS_HELPER) installed-size
_THEOS_HASH = $(_THEOS_WINDOWS_HELPER) hash
_THEOS_CHECK_FILES = $(_THEOS_WINDOWS_HELPER) check-files
_THEOS_COPY_LIST = $(_THEOS_WINDOWS_HELPER) copy-list
_THEOS_SUBPROJECTS = $(_THEOS_WINDOWS_HELPER) subprojects
_THEOS_SCHEME_STAGE_CMD = $(_THEOS_WINDOWS_HELPER) scheme-stage
_THEOS_LOGOS_CMD = $(_THEOS_WINDOWS_HELPER) logos --perl perl
_THEOS_IPA_CMD = $(_THEOS_WINDOWS_HELPER) ipa
_THEOS_DEB_CMD = $(_THEOS_WINDOWS_HELPER) deb
_THEOS_MACHO_CHECK = $(_THEOS_WINDOWS_HELPER) macho-check
_THEOS_SIGN_TREE = $(_THEOS_WINDOWS_HELPER) sign-tree
ifneq ($(strip $(THEOS_LDID)),)
_THEOS_LDID := $(THEOS_LDID)
else ifeq ($(call __executable,ldid.exe),$(_THEOS_TRUE))
_THEOS_LDID := ldid.exe
else ifeq ($(call __executable,ldid),$(_THEOS_TRUE))
_THEOS_LDID := ldid
else
_THEOS_LDID :=
endif
_THEOS_RPM_SPEC_CMD = $(_THEOS_WINDOWS_HELPER) rpm-spec
_THEOS_OPTIMIZE_PLISTS_CMD = $(_THEOS_WINDOWS_HELPER) optimize-plists
_THEOS_WHERE = where
_THEOS_PLATFORM_MD5SUM = $(_THEOS_HASH)

# Native fakeroot backend. The Bash fakeroot.sh shim cannot run here, and Windows
# has no POSIX ownership database, so staging metadata is recorded by the helper
# and consumed by the native packager instead of being emulated through a
# ptrace/LD_PRELOAD-style shim. The `-p`/`-c`/`-r` interface is preserved.
_THEOS_FAKEROOT_STATE := $(_THEOS_LOCAL_DATA_DIR)/fakeroot
_THEOS_FAKEROOT_MANIFEST := $(_THEOS_FAKEROOT_STATE).json
FAKEROOT := $(_THEOS_WINDOWS_HELPER) fakeroot --persistence "$(_THEOS_FAKEROOT_STATE)"
export FAKEROOT
endif
