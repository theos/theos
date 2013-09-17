ifeq ($(_THEOS_PACKAGE_RULES_LOADED),)
_THEOS_PACKAGE_RULES_LOADED := 1

## Packaging Core Rules
.PHONY: package internal-package-check before-package internal-package after-package

package:: internal-package-check stage before-package internal-package after-package
internal-package-check::
before-package:: $(THEOS_PACKAGE_DIR)
internal-package::

# __THEOS_LAST_PACKAGE_FILENAME is to be set by a rule variable in the package format makefile.
after-package::
	@echo "$(__THEOS_LAST_PACKAGE_FILENAME)" > "$(_THEOS_LOCAL_DATA_DIR)/last_package"

THEOS_PACKAGE_NAME :=
THEOS_PACKAGE_ARCH :=
THEOS_PACKAGE_BASE_VERSION :=
# THEOS_PACKAGE_VERSION is set in common.mk (to give its warning.)

-include $(THEOS_MAKE_PATH)/package/$(_THEOS_PACKAGE_FORMAT).mk
$(eval $(call __mod,package/$(_THEOS_PACKAGE_FORMAT).mk))

ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
$(error I simply cannot figure out how to create $(_THEOS_PACKAGE_FORMAT)-format packages.)
endif

export THEOS_PACKAGE_NAME THEOS_PACKAGE_ARCH THEOS_PACKAGE_BASE_VERSION

# These are here to be used by the package makefile included above.
# We want them after the package makefile so that we can use variables set within it.
#
# eval PACKAGE_VERSION *now* (to clear out references to THEOS_PACKAGE_INC_BUILD_NUMBER)
THEOS_PACKAGE_INC_BUILD_NUMBER := X
__USERVER_FOR_BUILDNUM := $(PACKAGE_VERSION)
__BASEVER_FOR_BUILDNUM = $(or $(__USERVER_FOR_BUILDNUM),$(THEOS_PACKAGE_BASE_VERSION))

# THEOS_PACKAGE_INC_BUILD_NUMBER is meant to be used in user PACKAGE_VERSIONs.
# We simplify the version vars so that they are evaluated only when completely necessary.
THEOS_PACKAGE_INC_BUILD_NUMBER = $(shell THEOS_PROJECT_DIR="$(THEOS_PROJECT_DIR)" "$(THEOS_BIN_PATH)/package_version.sh" -N "$(THEOS_PACKAGE_NAME)" -V "$(__BASEVER_FOR_BUILDNUM)")
_THEOS_PACKAGE_DEFAULT_VERSION_FORMAT = $(THEOS_PACKAGE_BASE_VERSION)-$(THEOS_PACKAGE_INC_BUILD_NUMBER)
_PACKAGE_VERSION = $(call __schema_var_last,,PACKAGE_VERSION)
_THEOS_INTERNAL_PACKAGE_VERSION = $(call __simplify,_THEOS_INTERNAL_PACKAGE_VERSION,$(or $(_PACKAGE_VERSION),$(_THEOS_PACKAGE_DEFAULT_VERSION_FORMAT),1))

## Installation Core Rules
install:: before-install internal-install after-install

export TARGET_INSTALL_REMOTE
_THEOS_INSTALL_TYPE := local
ifeq ($(TARGET_INSTALL_REMOTE),$(_THEOS_TRUE))
_THEOS_INSTALL_TYPE := remote
ifeq ($(THEOS_DEVICE_IP),)
internal-install::
	$(info $(MAKE) install requires that you set THEOS_DEVICE_IP in your environment. It is also recommended that you have public-key authentication set up for root over SSH, or you will be entering your password a lot.)
	@exit 1
endif # THEOS_DEVICE_IP == ""
THEOS_DEVICE_PORT ?= 22
export THEOS_DEVICE_IP THEOS_DEVICE_PORT
endif # TARGET_INSTALL_REMOTE == true

before-install::
internal-install::
after-install:: internal-after-install
internal-after-install::

-include $(THEOS_MAKE_PATH)/install/$(_THEOS_PACKAGE_FORMAT)_$(_THEOS_INSTALL_TYPE).mk
$(eval $(call __mod,install/$(_THEOS_PACKAGE_FORMAT)_$(_THEOS_INSTALL_TYPE).mk))

endif # _THEOS_PACKAGE_RULES_LOADED
