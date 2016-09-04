ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
_THEOS_PACKAGE_FORMAT_LOADED := 1

_THEOS_PLATFORM_DU ?= du
_THEOS_PLATFORM_DPKG_DEB ?= dpkg-deb
_THEOS_PLATFORM_DPKG_DEB_COMPRESSION ?= lzma

_THEOS_DEB_PACKAGE_CONTROL_PATH := $(or $(wildcard $(THEOS_PROJECT_DIR)/control),$(wildcard $(THEOS_LAYOUT_DIR)/DEBIAN/control))
_THEOS_DEB_CAN_PACKAGE := $(if $(_THEOS_DEB_PACKAGE_CONTROL_PATH),$(_THEOS_TRUE),$(_THEOS_FALSE))
_THEOS_PACKAGE_INC_VERSION_PREFIX := -
_THEOS_PACKAGE_EXTRA_VERSION_PREFIX := +

_THEOS_DEB_HAS_DPKG_DEB := $(call __executable,$(_THEOS_PLATFORM_DPKG_DEB))

ifneq ($(_THEOS_DEB_HAS_DPKG_DEB),$(_THEOS_TRUE))
internal-package-check::
	@$(PRINT_FORMAT_ERROR) "$(MAKE) package requires $(_THEOS_PLATFORM_DPKG_DEB)." >&2; exit 1
endif

ifeq ($(_THEOS_DEB_CAN_PACKAGE),$(_THEOS_TRUE)) # Control file found (or layout directory found.)
THEOS_PACKAGE_NAME := $(shell grep -i "^Package:" "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_ARCH := $(shell grep -i "^Architecture:" "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_BASE_VERSION := $(shell grep -i "^Version:" "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)

$(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN:
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/DEBIAN"$(ECHO_END)
ifeq ($(_THEOS_HAS_STAGING_LAYOUT),1) # If we have a layout directory, copy layout/DEBIAN to the staging directory.
	$(ECHO_NOTHING)[ -d "$(THEOS_LAYOUT_DIR)/DEBIAN" ] && rsync -a "$(THEOS_LAYOUT_DIR)/DEBIAN/" "$(THEOS_STAGING_DIR)/DEBIAN" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE) || true$(ECHO_END)
endif # _THEOS_HAS_STAGING_LAYOUT

$(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN/control: $(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN
	$(ECHO_NOTHING)sed -e '/^[Vv]ersion:/d; /^$$/d; $$a\' "$(_THEOS_DEB_PACKAGE_CONTROL_PATH)" > "$@"$(ECHO_END)
	$(ECHO_NOTHING)echo "Version: $(_THEOS_INTERNAL_PACKAGE_VERSION)" >> "$@"$(ECHO_END)
	$(ECHO_NOTHING)echo "Installed-Size: $(shell $(_THEOS_PLATFORM_DU) $(_THEOS_PLATFORM_DU_EXCLUDE) DEBIAN -ks "$(THEOS_STAGING_DIR)" | cut -f 1)" >> "$@"$(ECHO_END)

before-package:: $(_THEOS_ESCAPED_STAGING_DIR)/DEBIAN/control

_THEOS_DEB_PACKAGE_FILENAME = $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(_THEOS_INTERNAL_PACKAGE_VERSION)_$(THEOS_PACKAGE_ARCH).deb
internal-package::
	$(ECHO_NOTHING)COPYFILE_DISABLE=1 $(FAKEROOT) -r $(_THEOS_PLATFORM_DPKG_DEB) -Z$(_THEOS_PLATFORM_DPKG_DEB_COMPRESSION) -b "$(THEOS_STAGING_DIR)" "$(_THEOS_DEB_PACKAGE_FILENAME)"$(ECHO_END)

# This variable is used in package.mk
after-package:: __THEOS_LAST_PACKAGE_FILENAME = $(_THEOS_DEB_PACKAGE_FILENAME)

else # _THEOS_DEB_CAN_PACKAGE == 0
internal-package::
	@$(PRINT_FORMAT_ERROR) "$(MAKE) package requires you to have a layout/ directory in the project root, containing the basic package structure, or a control file in the project root describing the package." >&2; exit 1

endif # _THEOS_DEB_CAN_PACKAGE
endif # _THEOS_PACKAGE_FORMAT_LOADED
