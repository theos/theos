ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
_THEOS_PACKAGE_FORMAT_LOADED := 1

_THEOS_DEB_PACKAGE_CONTROL_PATH := $(or $(wildcard $(THEOS_PROJECT_DIR)/control),$(wildcard $(THEOS_PROJECT_DIR)/layout/DEBIAN/control))
_THEOS_DEB_CAN_PACKAGE := $(if $(_THEOS_DEB_PACKAGE_CONTROL_PATH),$(_THEOS_TRUE),$(_THEOS_FALSE))

_THEOS_DEB_HAS_DPKG_DEB := $(call __executable,dpkg-deb)
ifneq ($(_THEOS_DEB_HAS_DPKG_DEB),$(_THEOS_TRUE))
internal-package-check::
	@echo "$(MAKE) package requires dpkg-deb."; exit 1
endif

ifeq ($(_THEOS_DEB_CAN_PACKAGE),$(_THEOS_TRUE)) # Control file found (or layout/ found.)
THEOS_PACKAGE_NAME := $(shell grep -i "^Package:" "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_ARCH := $(shell grep -i "^Architecture:" "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_BASE_VERSION := $(shell grep -i "^Version:" "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)

THEOS_PACKAGE_VERSION = $(warning THEOS_PACKAGE_VERSION is deprecated)$(THEOS_PACKAGE_BASE_VERSION)
_THEOS_PACKAGE_VERSION = $(call __simplify,THEOS_PACKAGE_VERSION,$(shell grep -i "^Version:" "$(THEOS_STAGING_DIR)/DEBIAN/control" | cut -d' ' -f2-))
export THEOS_PACKAGE_NAME THEOS_PACKAGE_ARCH THEOS_PACKAGE_BASE_VERSION

$(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN/control:
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/DEBIAN"$(ECHO_END)
ifeq ($(_THEOS_HAS_STAGING_LAYOUT),1) # If we have a layout/ directory, copy layout/DEBIAN to the staging directory.
	$(ECHO_NOTHING)rsync -a "$(THEOS_PROJECT_DIR)/layout/DEBIAN/" "$(THEOS_STAGING_DIR)/DEBIAN" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE)$(ECHO_END)
endif # _THEOS_HAS_STAGING_LAYOUT
	$(ECHO_NOTHING)$(THEOS_BIN_PATH)/package_version.sh -c "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" $(if $(PACKAGE_BUILDNAME),-e $(PACKAGE_BUILDNAME),) > "$@"$(ECHO_END)
	$(ECHO_NOTHING)echo "Installed-Size: $(shell du $(_THEOS_PLATFORM_DU_EXCLUDE) DEBIAN -ks "$(THEOS_STAGING_DIR)" | cut -f 1)" >> "$@"$(ECHO_END)

before-package:: $(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN/control

internal-package:: THEOS_PACKAGE_FILENAME = $(THEOS_PACKAGE_NAME)_$(_THEOS_PACKAGE_VERSION)_$(THEOS_PACKAGE_ARCH)
internal-package::
	$(ECHO_NOTHING)COPYFILE_DISABLE=1 $(FAKEROOT) -r dpkg-deb -b "$(THEOS_STAGING_DIR)" "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" $(STDERR_NULL_REDIRECT)$(ECHO_END)
	@echo "$(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_FILENAME).deb" > "$(_THEOS_LOCAL_DATA_DIR)/last_package"

else # _THEOS_DEB_CAN_PACKAGE == 0
internal-package::
	@echo "$(MAKE) package requires you to have a layout/ directory in the project root, containing the basic package structure, or a control file in the project root describing the package."; exit 1

endif # _THEOS_DEB_CAN_PACKAGE

before-package::
after-package::

before-install::
after-install:: internal-after-install
internal-after-install::

endif # _THEOS_PACKAGE_FORMAT_LOADED
