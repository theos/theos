ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

.PHONY: internal-xcodeproj-all_ internal-xcodeproj-stage_ internal-xcodeproj-compile

ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING), no)
internal-xcodeproj-all_:: internal-xcodeproj-compile
else
internal-xcodeproj-all_::
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) \
		internal-xcodeproj-compile \
		_THEOS_CURRENT_TYPE=$(_THEOS_CURRENT_TYPE) THEOS_CURRENT_INSTANCE=$(THEOS_CURRENT_INSTANCE) _THEOS_CURRENT_OPERATION=compile \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" _THEOS_MAKE_PARALLEL=yes
endif

ALL_XCODEFLAGS = $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,XCODEFLAGS)
ALL_XCODEOPTS = $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,XCODEOPTS)

ifneq ($(TARGET_XCPRETTY),)
ifneq ($(_THEOS_VERBOSE),$(_THEOS_TRUE))
	_THEOS_XCODE_XCPRETTY = | $(TARGET_XCPRETTY)
endif
endif

ifeq ($(findstring DEBUG,$(THEOS_SCHEMA)),)
	_THEOS_XCODE_BUILD_CONFIG = Release
else
	_THEOS_XCODE_BUILD_CONFIG = Debug
endif

_THEOS_XCODEBUILD_BEGIN = $(ECHO_NOTHING)set -e; $(TARGET_XCODEBUILD) -scheme '$(THEOS_CURRENT_INSTANCE)' -configuration $(_THEOS_XCODE_BUILD_CONFIG) -derivedDataPath $(THEOS_OBJ_DIR)
_THEOS_XCODEBUILD_END = CODE_SIGNING_ALLOWED=NO DSTROOT=$(THEOS_OBJ_DIR)/install $(_THEOS_XCODE_XCPRETTY)$(ECHO_END)
export EXPANDED_CODE_SIGN_IDENTITY =
export EXPANDED_CODE_SIGN_IDENTITY_NAME =

# TODO: sign in a depth-first manner
internal-xcodeproj-compile:
	$(_THEOS_XCODEBUILD_BEGIN) \
	$(ALL_XCODEOPTS) \
	build install \
	$(ALL_XCODEFLAGS) \
	$(_THEOS_XCODEBUILD_END)
ifeq ($(_THEOS_PACKAGE_FORMAT),deb)
	$(ECHO_NOTHING)find $(THEOS_OBJ_DIR)/install -name 'libswift*.dylib' -delete$(ECHO_END)
endif
ifneq ($(_THEOS_CODESIGN_COMMANDLINE),)
	$(ECHO_SIGNING)function process_exec { \
		$(_THEOS_CODESIGN_COMMANDLINE) $$1; \
	}; \
	function process_bundle { \
		process_exec $$1/$$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" $$1/Info.plist); \
	}; \
	export -f process_exec process_bundle; \
	find $(THEOS_OBJ_DIR)/install -name '*.dylib' -print0 | xargs -I{} -0 bash -c 'process_exec "$$@"' _ {}; \
	find $(THEOS_OBJ_DIR)/install -name '*.framework' -print0 | xargs -I{} -0 bash -c 'process_bundle "$$@"' _ {}; \
	find $(THEOS_OBJ_DIR)/install -name '*.appex' -print0 | xargs -I{} -0 bash -c 'process_bundle "$$@"' _ {}; \
	find $(THEOS_OBJ_DIR)/install -name '*.app' -print0 | xargs -I{} -0 bash -c 'process_bundle "$$@"' _ {}; \
	$(ECHO_END)
endif

ifneq ($($(THEOS_CURRENT_INSTANCE)_INSTALL),0)
internal-xcodeproj-stage_::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)"$(ECHO_END)
	$(ECHO_NOTHING)rsync -a $(THEOS_OBJ_DIR)/install/ "$(THEOS_STAGING_DIR)" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE)$(ECHO_END)
endif

$(eval $(call __mod,instance/xcodeproj.mk))
