ifeq ($(FW_PACKAGING_RULES_LOADED),)
FW_PACKAGING_RULES_LOADED := 1

.PHONY: package before-package internal-package after-package-buildno after-package \
	stage before-stage internal-stage after-stage

# For the toplevel invocation of make, mark 'all' and the *-package rules as prerequisites.
# We do not do this for anything else, because otherwise, all the packaging rules would run for every subproject.
ifeq ($(_FW_TOP_INVOCATION_DONE),)
stage:: all before-stage internal-stage after-stage

_FW_HAS_DPKG_DEB := $(shell type dpkg-deb > /dev/null 2>&1 && echo 1 || echo 0)
ifeq ($(_FW_HAS_DPKG_DEB),1)
package:: stage package-build-deb
else # _FW_HAS_DPKG_DEB == 0
package::
	@echo "$(MAKE) package requires dpkg-deb."; exit 1
endif

install:: before-install internal-install after-install
else # _FW_TOP_INVOCATION_DONE
stage:: internal-stage
package::
install::
endif

FAKEROOT := $(FW_BINDIR)/fakeroot.sh -p "$(FW_PROJECT_DIR)/.debmake/fakeroot"
export FAKEROOT

# Only do the master packaging rules if we're the toplevel make invocation.
ifeq ($(_FW_TOP_INVOCATION_DONE),)
before-stage::
	$(ECHO_NOTHING)rm -rf "$(FW_STAGING_DIR)"$(ECHO_END)
	$(ECHO_NOTHING)$(FAKEROOT) -c$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p "$(FW_STAGING_DIR)"$(ECHO_END)

ifeq ($(FW_CAN_PACKAGE),1) # Control file found (or layout/ found.)

FW_PACKAGE_NAME := $(shell grep "^Package:" "$(FW_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2)
FW_PACKAGE_ARCH := $(shell grep "^Architecture:" "$(FW_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2)
FW_PACKAGE_VERSION := $(shell grep "^Version:" "$(FW_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2)

FW_PACKAGE_DEBVERSION = $(shell grep "^Version:" "$(FW_STAGING_DIR)/DEBIAN/control" | cut -d' ' -f2)

FW_PACKAGE_FILENAME = $(FW_PACKAGE_NAME)_$(FW_PACKAGE_DEBVERSION)_$(FW_PACKAGE_ARCH)

package-build-deb-buildno::
	$(ECHO_NOTHING)mkdir -p $(FW_STAGING_DIR)/DEBIAN$(ECHO_END)
ifeq ($(FW_HAS_LAYOUT),1) # If we have a layout/ directory, copy layout/DEBIAN to the staging directory.
	$(ECHO_NOTHING)rsync -a "$(FW_PROJECT_DIR)/layout/DEBIAN/" "$(FW_STAGING_DIR)/DEBIAN" $(FW_RSYNC_EXCLUDES)$(ECHO_END)
endif # FW_HAS_LAYOUT
	$(ECHO_NOTHING)$(FW_BINDIR)/package_version.sh -c "$(FW_PACKAGE_CONTROL_PATH)" $(if $(PACKAGE_BUILDNAME),-e $(PACKAGE_BUILDNAME),) > "$(FW_STAGING_DIR)/DEBIAN/control"$(ECHO_END)
	$(ECHO_NOTHING)echo "Installed-Size: $(shell du $(DU_EXCLUDE) DEBIAN -ks "$(FW_STAGING_DIR)" | cut -f 1)" >> "$(FW_STAGING_DIR)/DEBIAN/control"$(ECHO_END)

package-build-deb:: package-build-deb-buildno
	$(ECHO_NOTHING)$(FAKEROOT) -r dpkg-deb -b "$(FW_STAGING_DIR)" "$(FW_PROJECT_DIR)/$(FW_PACKAGE_FILENAME).deb" $(STDERR_NULL_REDIRECT)$(ECHO_END)

else # FW_CAN_PACKAGE == 0
package-build-deb::
	@echo "$(MAKE) package requires you to have a layout/ directory in the project root, containing the basic package structure, or a control file in the project root describing the package."; exit 1

endif # FW_CAN_PACKAGE

endif # _FW_TOP_INVOCATION_DONE

# *-stage calls *-package for backwards-compatibility.
internal-package after-package::
internal-stage:: internal-package
	$(ECHO_NOTHING)[ -d layout ] && rsync -a "layout/" "$(FW_STAGING_DIR)" --exclude "DEBIAN" $(FW_RSYNC_EXCLUDES) || true$(ECHO_END)

after-stage:: after-package

before-install::
after-install:: internal-after-install
internal-after-install::

endif # FW_PACKAGING_RULES_LOADED
