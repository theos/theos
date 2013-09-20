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

-include $(THEOS_MAKE_PATH)/package/$(_THEOS_PACKAGE_FORMAT).mk
$(eval $(call __mod,package/$(_THEOS_PACKAGE_FORMAT).mk))

ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
$(error I simply cannot figure out how to create $(_THEOS_PACKAGE_FORMAT)-format packages.)
endif

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
