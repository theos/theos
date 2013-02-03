ifeq ($(_THEOS_PACKAGE_RULES_LOADED),)
_THEOS_PACKAGE_RULES_LOADED := 1

.PHONY: package internal-before-package before-package internal-package after-package

_THEOS_HAS_DPKG_DEB := $(shell PATH="$(THEOS_BIN_PATH):$$PATH" type dpkg-deb > /dev/null 2>&1 && echo 1 || echo 0)
ifeq ($(_THEOS_HAS_DPKG_DEB),1)
package:: stage before-package internal-package after-package
else # _THEOS_HAS_DPKG_DEB == 0
package::
	@echo "$(MAKE) package requires dpkg-deb."; exit 1
endif

install:: before-install internal-install after-install

FAKEROOT := $(THEOS_BIN_PATH)/fakeroot.sh -p "$(THEOS_PROJECT_DIR)/.theos/fakeroot"
export FAKEROOT

ifeq ($(_THEOS_CAN_PACKAGE),$(_THEOS_TRUE)) # Control file found (or layout/ found.)
THEOS_PACKAGE_NAME := $(shell grep "^Package:" "$(_THEOS_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_ARCH := $(shell grep "^Architecture:" "$(_THEOS_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_BASE_VERSION := $(shell grep "^Version:" "$(_THEOS_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)

THEOS_PACKAGE_VERSION = $(shell THEOS_PROJECT_DIR="$(THEOS_PROJECT_DIR)" $(THEOS_BIN_PATH)/package_version.sh -n -o -c "$(_THEOS_PACKAGE_CONTROL_PATH)" $(if $(PACKAGE_BUILDNAME),-e $(PACKAGE_BUILDNAME),))
export THEOS_PACKAGE_NAME THEOS_PACKAGE_ARCH THEOS_PACKAGE_BASE_VERSION THEOS_PACKAGE_VERSION

THEOS_PACKAGE_FILENAME = $(THEOS_PACKAGE_NAME)_$(_THEOS_PACKAGE_LAST_VERSION)_$(THEOS_PACKAGE_ARCH)

$(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN/control:
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/DEBIAN"$(ECHO_END)
ifeq ($(_THEOS_HAS_STAGING_LAYOUT),1) # If we have a layout/ directory, copy layout/DEBIAN to the staging directory.
	$(ECHO_NOTHING)rsync -a "$(THEOS_PROJECT_DIR)/layout/DEBIAN/" "$(THEOS_STAGING_DIR)/DEBIAN" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE)$(ECHO_END)
endif # _THEOS_HAS_STAGING_LAYOUT
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/package_version.sh -c "$(_THEOS_PACKAGE_CONTROL_PATH)" $(if $(PACKAGE_BUILDNAME),-e $(PACKAGE_BUILDNAME),) > "$@"$(ECHO_END)
	$(ECHO_NOTHING)echo "Installed-Size: $(shell du $(_THEOS_PLATFORM_DU_EXCLUDE) DEBIAN -ks "$(THEOS_STAGING_DIR)" | cut -f 1)" >> "$@"$(ECHO_END)

before-package:: $(THEOS_PACKAGE_DIR) $(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN/control

internal-package::
	$(ECHO_NOTHING)COPYFILE_DISABLE=1 $(FAKEROOT) -r dpkg-deb -b "$(THEOS_STAGING_DIR)" "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" $(STDERR_NULL_REDIRECT)$(ECHO_END)

else # _THEOS_CAN_PACKAGE == 0
internal-package::
	@echo "$(MAKE) package requires you to have a layout/ directory in the project root, containing the basic package structure, or a control file in the project root describing the package."; exit 1

endif # _THEOS_CAN_PACKAGE

before-package::
after-package::

before-install::
after-install:: internal-after-install
internal-after-install::

endif # _THEOS_PACKAGE_RULES_LOADED
