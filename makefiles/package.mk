ifeq ($(_THEOS_PACKAGE_RULES_LOADED),)
_THEOS_PACKAGE_RULES_LOADED := 1

## Packaging Core Rules
.PHONY: package internal-package-check before-package internal-package after-package

package:: internal-package-check stage before-package internal-package after-package
before-package:: $(THEOS_PACKAGE_DIR)
internal-package internal-package-check::
	@:

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

# eval PACKAGE_VERSION *now* (to clear out references to VERSION.*: they have no bearing on
# the 'base' version we calculate.)
VERSION.INC_BUILD_NUMBER := X
VERSION.EXTRAVERSION := X
__USERVER_FOR_BUILDNUM := $(PACKAGE_VERSION)
__BASEVER_FOR_BUILDNUM = $(or $(__USERVER_FOR_BUILDNUM),$(THEOS_PACKAGE_BASE_VERSION))


# We simplify the version vars so that they are evaluated only when completely necessary.
# This is because they can include things like incrementing build numbers.

# I am committing a willful departure from the THEOS_ naming convention, because I believe
# that offering these via an easy-to-use interface makes more sense than hiding them behind
# a really stupidly long name.
# VERSION.* are meant to be used in user PACKAGE_VERSIONs.
VERSION.INC_BUILD_NUMBER = $(shell THEOS_PROJECT_DIR="$(THEOS_PROJECT_DIR)" "$(THEOS_BIN_PATH)/package_version.sh" -N "$(THEOS_PACKAGE_NAME)" -V "$(__BASEVER_FOR_BUILDNUM)")
VERSION.EXTRAVERSION = $(if $(PACKAGE_BUILDNAME),+$(PACKAGE_BUILDNAME))
_THEOS_PACKAGE_DEFAULT_VERSION_FORMAT = $(THEOS_PACKAGE_BASE_VERSION)-$(VERSION.INC_BUILD_NUMBER)$(VERSION.EXTRAVERSION)

# Copy the actual value of PACKAGE_VERSION to __PACKAGE_VERSION and replace PACKAGE_VERSION with
# a mere reference (to a simplified copy.)
# We're doing this to clean up the user's PACKAGE_VERSION and make it safe for reuse.
# (otherwise, they might trigger build number increases without meaning to.)
# Defer the simplification until __PACKAGE_VERSION is used - do not do it before the eval
# However, we want to do the schema calculation and value stuff before the eval, so that
# __PACKAGE_VERSION becomes an exact copy of the PACKAGE_VERSION variable we chose.
$(eval __PACKAGE_VERSION = $$(call __simplify,__PACKAGE_VERSION,$(value $(call __schema_var_name_last,,PACKAGE_VERSION))))
override PACKAGE_VERSION = $(__PACKAGE_VERSION)

_THEOS_INTERNAL_PACKAGE_VERSION = $(call __simplify,_THEOS_INTERNAL_PACKAGE_VERSION,$(or $(__PACKAGE_VERSION),$(_THEOS_PACKAGE_DEFAULT_VERSION_FORMAT),1))

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

after-install:: internal-after-install
before-install internal-install internal-after-install::
	@:

-include $(THEOS_MAKE_PATH)/install/$(_THEOS_PACKAGE_FORMAT)_$(_THEOS_INSTALL_TYPE).mk
$(eval $(call __mod,install/$(_THEOS_PACKAGE_FORMAT)_$(_THEOS_INSTALL_TYPE).mk))

endif # _THEOS_PACKAGE_RULES_LOADED
