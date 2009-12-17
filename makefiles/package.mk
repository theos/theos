ifeq ($(FW_PACKAGING_RULES_LOADED),)
FW_PACKAGING_RULES_LOADED := 1

.PHONY: package before-package internal-package after-package-buildno after-package

package:: all before-package internal-package after-package

FW_PACKAGE_NAME := $(shell grep Package $(TOP_DIR)/layout/DEBIAN/control | cut -d' ' -f2)
FW_PACKAGE_ARCH := $(shell grep Architecture $(TOP_DIR)/layout/DEBIAN/control | cut -d' ' -f2)
FW_PACKAGE_VERSION := $(shell grep Version $(TOP_DIR)/layout/DEBIAN/control | cut -d' ' -f2)

FW_PACKAGE_BUILDNUM = $(shell TOP_DIR="$(TOP_DIR)" $(FW_SCRIPTDIR)/deb_build_num.sh $(FW_PACKAGE_NAME) $(FW_PACKAGE_VERSION))
FW_PACKAGE_DEBVERSION = $(shell grep Version $(FW_PACKAGE_STAGING_DIR)/DEBIAN/control | cut -d' ' -f2)

ifdef STOREPACKAGE
	FW_PACKAGE_FILENAME = cydiastore_$(FW_PACKAGE_NAME)_v$(FW_PACKAGE_DEBVERSION)
else
	FW_PACKAGE_FILENAME = $(FW_PACKAGE_NAME)_$(FW_PACKAGE_DEBVERSION)_$(FW_PACKAGE_ARCH)
endif

FAKEROOT := $(FW_SCRIPTDIR)/fakeroot.sh -p "$(FW_PROJECT_DIR)/.debmake/fakeroot"

# Only do the master packaging rules if we're the toplevel make invocation.
ifeq ($(MAKELEVEL),0)

before-package::
	-rm -rf $(FW_PACKAGE_STAGING_DIR)
	svn export $(FW_PROJECT_DIR)/layout $(FW_PACKAGE_STAGING_DIR) || cp -r $(FW_PROJECT_DIR)/layout $(FW_PACKAGE_STAGING_DIR)
	$(FAKEROOT) -c

internal-package::

after-package-buildno::
	echo "Installed-Size: $(shell du -ks _ | cut -f 1)" >> $(FW_PACKAGE_STAGING_DIR)/DEBIAN/control
	sed -i'' -e 's/Version: \(.*\)/Version: \1-$(FW_PACKAGE_BUILDNUM)/g' $(FW_PACKAGE_STAGING_DIR)/DEBIAN/control

after-package:: after-package-buildno
	$(FAKEROOT) -r dpkg-deb -b $(FW_PACKAGE_STAGING_DIR) $(FW_PROJECT_DIR)/$(FW_PACKAGE_FILENAME).deb

else

before-package::

internal-package::

after-package::

endif # MAKELEVEL

endif # FW_PACKAGING_RULES_LOADED
