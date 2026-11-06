ifeq ($(_THEOS_PACKAGE_FORMAT_LOADED),)
_THEOS_PACKAGE_FORMAT_LOADED := 1

_THEOS_IPA_PACKAGE_CONTROL_PATH := $(THEOS_PROJECT_DIR)/control
_THEOS_IPA_CAN_PACKAGE := $(call __exists,$(_THEOS_IPA_PACKAGE_CONTROL_PATH))
_THEOS_PACKAGE_INC_VERSION_PREFIX := -
_THEOS_PACKAGE_EXTRA_VERSION_PREFIX := +

ifeq ($(OS),Windows_NT)
_THEOS_IPA_HAS_IPABUILD := $(_THEOS_TRUE)
else
_THEOS_IPA_HAS_IPABUILD := $(call __executable,zip)
endif
ifneq ($(_THEOS_IPA_HAS_IPABUILD),$(_THEOS_TRUE))
internal-package-check::
	@echo "$(MAKE) package requires zip."; exit 1
endif

_THEOS_IPA_COMPRESSION_LEVEL := 1
ifeq ($(_THEOS_FINAL_PACKAGE),$(_THEOS_TRUE))
_THEOS_IPA_COMPRESSION_LEVEL := 9
endif

ifeq ($(_THEOS_IPA_CAN_PACKAGE),$(_THEOS_TRUE)) # Control file found
ifeq ($(OS),Windows_NT)
THEOS_PACKAGE_NAME := $(shell $(_THEOS_CONTROL_FIELD) "$(_THEOS_IPA_PACKAGE_CONTROL_PATH)" Package)
THEOS_PACKAGE_BASE_VERSION := $(shell $(_THEOS_CONTROL_FIELD) "$(_THEOS_IPA_PACKAGE_CONTROL_PATH)" Version)
else
THEOS_PACKAGE_NAME := $(shell grep -i "^Package:" "$(_THEOS_IPA_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
THEOS_PACKAGE_BASE_VERSION := $(shell grep -i "^Version:" "$(_THEOS_IPA_PACKAGE_CONTROL_PATH)" | cut -d' ' -f2-)
endif

_THEOS_ABSOLUTE_PACKAGE_DIR = $(THEOS_PROJECT_DIR)/$(THEOS_PACKAGE_DIR)
_THEOS_IPA_PACKAGE_FILENAME = $(_THEOS_ABSOLUTE_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(_THEOS_INTERNAL_PACKAGE_VERSION).ipa
internal-package::
ifeq ($(OS),Windows_NT)
	$(ECHO_NOTHING)$(_THEOS_CP_CMD) "$(THEOS_STAGING_DIR)/Applications" "$(THEOS_STAGING_DIR)/Payload"$(ECHO_END)
	$(ECHO_NOTHING)$(_THEOS_IPA_CMD) "$(THEOS_STAGING_DIR)" "$(_THEOS_IPA_PACKAGE_FILENAME)" --compression "$(_THEOS_IPA_COMPRESSION_LEVEL)"$(ECHO_END)
else
	$(ECHO_NOTHING)cp -a $(THEOS_STAGING_DIR)/Applications $(THEOS_STAGING_DIR)/Payload; pushd $(THEOS_STAGING_DIR) &> /dev/null; zip -yqru$(_THEOS_IPA_COMPRESSION_LEVEL) "$(_THEOS_IPA_PACKAGE_FILENAME)" Payload; popd &> /dev/null$(ECHO_END)
endif

# This variable is used in package.mk
after-package:: __THEOS_LAST_PACKAGE_FILENAME = $(_THEOS_IPA_PACKAGE_FILENAME)

else # _THEOS_IPA_CAN_PACKAGE == 0
internal-package::
	@echo "$(MAKE) package requires you to have a control file in the project root. The control is used to determine info about the package (e.g., name and version)."; exit 1

endif # _THEOS_IPA_CAN_PACKAGE
endif # _THEOS_PACKAGE_FORMAT_LOADED
