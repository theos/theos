ifeq ($(FW_PACKAGING_RULES_LOADED),)
FW_PACKAGING_RULES_LOADED := 1

.PHONY: package before-package internal-package after-package-buildno after-package \
	stage before-stage internal-stage after-stage

# For the toplevel invocation of make, mark 'all' and the *-package rules as prerequisites.
# We do not do this for anything else, because otherwise, all the packaging rules would run for every subproject.
ifeq ($(_FW_TOP_INVOCATION_DONE),)
stage:: all before-stage internal-stage after-stage
package:: stage package-build-deb
else
stage:: internal-stage
package::
endif

FAKEROOT := $(FW_SCRIPTDIR)/fakeroot.sh -p "$(FW_PROJECT_DIR)/.debmake/fakeroot"
export FAKEROOT

# Only do the master packaging rules if we're the toplevel make invocation.
ifeq ($(_FW_TOP_INVOCATION_DONE),)
FW_HAS_LAYOUT := $(shell [ -d "$(FW_PROJECT_DIR)/layout" ] && echo 1 || echo 0)
ifeq ($(FW_HAS_LAYOUT),1)
	FW_PACKAGE_CONTROL_PATH := $(FW_PROJECT_DIR)/layout/DEBIAN/control
	FW_CAN_PACKAGE := 1
else # FW_HAS_LAYOUT == 0
	FW_PACKAGE_CONTROL_PATH := $(FW_PROJECT_DIR)/control
	FW_CAN_PACKAGE := $(shell [ -f "$(FW_PACKAGE_CONTROL_PATH)" ] && echo 1 || echo 0)
endif # FW_HAS_LAYOUT

before-stage::
	$(ECHO_NOTHING)rm -rf "$(FW_STAGING_DIR)"$(ECHO_END)
	$(ECHO_NOTHING)$(FAKEROOT) -c$(ECHO_END)
ifeq ($(FW_HAS_LAYOUT),1)
	$(ECHO_NOTHING)rsync -a "$(FW_PROJECT_DIR)/layout/" "$(FW_STAGING_DIR)" --exclude "DEBIAN" $(FW_RSYNC_EXCLUDES)$(ECHO_END)
else # FW_HAS_LAYOUT == 0
	$(ECHO_NOTHING)mkdir -p "$(FW_STAGING_DIR)"$(ECHO_END)
endif # FW_HAS_LAYOUT

ifeq ($(FW_CAN_PACKAGE),1) # Control file found (or layout/ found.)

FW_PACKAGE_NAME := $(shell grep Package "$(FW_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2)
FW_PACKAGE_ARCH := $(shell grep Architecture "$(FW_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2)
FW_PACKAGE_VERSION := $(shell grep Version "$(FW_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2)

ifdef FINALPACKAGE
FW_PACKAGE_DEBVERSION = $(FW_PACKAGE_VERSION)
else
FW_PACKAGE_BUILDNUM = $(shell TOP_DIR="$(TOP_DIR)" $(FW_SCRIPTDIR)/deb_build_num.sh $(FW_PACKAGE_NAME) $(FW_PACKAGE_VERSION))
FW_PACKAGE_DEBVERSION = $(shell grep Version "$(FW_STAGING_DIR)/DEBIAN/control" | cut -d' ' -f2)
endif

FW_PACKAGE_FILENAME = $(FW_PACKAGE_NAME)_$(FW_PACKAGE_DEBVERSION)_$(FW_PACKAGE_ARCH)

FW_DEVICE_USER ?= root

ifdef FW_DEVICE_TUNNEL
FW_DEVICE_PORT = 2222
FW_DEVICE_IP = 127.0.0.1
else
FW_DEVICE_PORT ?= 22
endif

package-build-deb-buildno::
	$(ECHO_NOTHING)mkdir -p $(FW_STAGING_DIR)/DEBIAN$(ECHO_END)
ifeq ($(FW_HAS_LAYOUT),1) # If we have a layout/ directory, copy layout/DEBIAN to the staging directory.
	$(ECHO_NOTHING)rsync -a "$(FW_PROJECT_DIR)/layout/DEBIAN/" "$(FW_STAGING_DIR)/DEBIAN" $(FW_RSYNC_EXCLUDES)$(ECHO_END)
endif # FW_HAS_LAYOUT
ifeq ($(FW_PACKAGE_BUILDNUM),)
	$(ECHO_NOTHING)sed -e 's/Version: \(.*\)/Version: \1$(if $(PACKAGE_BUILDNAME),+$(PACKAGE_BUILDNAME),)/g' "$(FW_PACKAGE_CONTROL_PATH)" > "$(FW_STAGING_DIR)/DEBIAN/control"$(ECHO_END)
else
	$(ECHO_NOTHING)sed -e 's/Version: \(.*\)/Version: \1-$(FW_PACKAGE_BUILDNUM)$(if $(PACKAGE_BUILDNAME),+$(PACKAGE_BUILDNAME),)/g' "$(FW_PACKAGE_CONTROL_PATH)" > "$(FW_STAGING_DIR)/DEBIAN/control"$(ECHO_END)
endif
	$(ECHO_NOTHING)echo "Installed-Size: $(shell du $(DU_EXCLUDE) DEBIAN -ks "$(FW_STAGING_DIR)" | cut -f 1)" >> "$(FW_STAGING_DIR)/DEBIAN/control"$(ECHO_END)

package-build-deb:: package-build-deb-buildno
	$(ECHO_NOTHING)$(FAKEROOT) -r dpkg-deb -b "$(FW_STAGING_DIR)" "$(FW_PROJECT_DIR)/$(FW_PACKAGE_FILENAME).deb" 2>/dev/null$(ECHO_END)

ifeq ($(INSTALL_LOCAL),1)
install:: internal-install after-install
internal-install::
	dpkg -i "$(FW_PROJECT_DIR)/$(FW_PACKAGE_FILENAME).deb"

after-install::
else # INSTALL_LOCAL
ifeq ($(FW_DEVICE_IP),)
install::
	@echo "Error: $(MAKE) install requires that you set FW_DEVICE_IP in your environment.\nIt is also recommended that you have public-key authentication set up for root over SSH, or you'll be entering your password a lot."; exit 1
else # FW_DEVICE_IP
install:: internal-install after-install
internal-install::
	scp -P $(FW_DEVICE_PORT) "$(FW_PROJECT_DIR)/$(FW_PACKAGE_FILENAME).deb" $(FW_DEVICE_USER)@$(FW_DEVICE_IP):
	ssh $(FW_DEVICE_USER)@$(FW_DEVICE_IP) -p $(FW_DEVICE_PORT) "dpkg -i $(FW_PACKAGE_FILENAME).deb"

after-install:: internal-after-install
endif
endif

else # FW_CAN_PACKAGE == 0
package-build-deb::
	@echo "$(MAKE) package requires you to have a layout/ directory in the project root, containing the basic package structure, or a control file in the project root describing the package."; exit 1

endif # FW_CAN_PACKAGE

endif # _FW_TOP_INVOCATION_DONE

# *-stage calls *-package for backwards-compatibility.
internal-package after-package::
internal-stage:: internal-package
after-stage:: after-package

internal-after-install::

endif # FW_PACKAGING_RULES_LOADED
