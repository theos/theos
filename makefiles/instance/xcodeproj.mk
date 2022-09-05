ifeq ($(_THEOS_RULES_LOADED),$(_THEOS_FALSE))
include $(THEOS_MAKE_PATH)/rules.mk
endif

.PHONY: internal-xcodeproj-all_ internal-xcodeproj-stage_ internal-xcodeproj-compile internal-xcodeproj-clean

ifeq ($(call __theos_bool,$(THEOS_USE_PARALLEL_BUILDING)),$(_THEOS_TRUE))
# Don't synchronize xcodeproj output, because doing so results in Make buffering
# the output and outputting it all at once once the build is finished. It's okay
# not to synchronize, because the entire compile phase is just one single rule
# which runs only once.
MAKEFLAGS += -Onone
endif

ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING), no)
internal-xcodeproj-all_:: internal-xcodeproj-compile
internal-clean:: internal-xcodeproj-clean
else
internal-xcodeproj-all_::
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) \
		internal-xcodeproj-compile \
		_THEOS_CURRENT_TYPE=$(_THEOS_CURRENT_TYPE) THEOS_CURRENT_INSTANCE=$(THEOS_CURRENT_INSTANCE) _THEOS_CURRENT_OPERATION=compile \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" _THEOS_MAKE_PARALLEL=yes

internal-clean::
	$(ECHO_MAKE)$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_MAKEFLAGS) \
		internal-xcodeproj-clean \
		_THEOS_CURRENT_TYPE=$(_THEOS_CURRENT_TYPE) THEOS_CURRENT_INSTANCE=$(THEOS_CURRENT_INSTANCE) _THEOS_CURRENT_OPERATION=compile \
		THEOS_BUILD_DIR="$(THEOS_BUILD_DIR)" _THEOS_MAKE_PARALLEL=yes
endif

ALL_XCODEFLAGS = $(_THEOS_INTERNAL_XCODEFLAGS) $(ADDITIONAL_XCODEFLAGS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,XCODEFLAGS) $(call __schema_var_all,,XCODEFLAGS)
ALL_XCODEOPTS = $(_THEOS_INTERNAL_XCODEOPTS) $(ADDITIONAL_XCODEOPTS) $(call __schema_var_all,$(THEOS_CURRENT_INSTANCE)_,XCODEOPTS) $(call __schema_var_all,,XCODEOPTS)

_THEOS_INTERNAL_XCODEOPTS = -sdk $(_THEOS_TARGET_PLATFORM_NAME)

# Xcode strips even debug builds, which is an issue when using lldb because it's unable to
# locate the local unstripped copy since it isn't aware of our custom derivedDataPath. While
# that underlying issue still needs to be resolved to allow debugging release builds, the
# following is a more immediate solution until we get around to solving that – which we could
# do by, for example, writing a DBGShellCommands script or using DBGFileMappedPaths.
_THEOS_INTERNAL_XCODEFLAGS += STRIP_INSTALLED_PRODUCT=$(if $(SHOULD_STRIP),YES,NO)

ifneq ($(TARGET_XCPRETTY),)
ifneq ($(_THEOS_VERBOSE),$(_THEOS_TRUE))
	_THEOS_XCODE_XCPRETTY = | $(TARGET_XCPRETTY)
endif
endif

_THEOS_XCODE_BUILD_CONFIG = $(if $(findstring DEBUG,$(THEOS_SCHEMA)),Debug,Release)
_THEOS_XCODE_BUILD_COMMAND := $(if $(_THEOS_FINAL_PACKAGE),archive,build install)

# Try a workspace or project the user has already specified, falling back to figuring out the
# workspace or project ourselves based on the instance name.
ifneq ($($(THEOS_CURRENT_INSTANCE)_XCODE_WORKSPACE),)
	_THEOS_XCODEBUILD_PROJECT_FLAG := -workspace $($(THEOS_CURRENT_INSTANCE)_XCODE_WORKSPACE)
else ifneq ($($(THEOS_CURRENT_INSTANCE)_XCODE_PROJECT),)
	_THEOS_XCODEBUILD_PROJECT_FLAG := -project $($(THEOS_CURRENT_INSTANCE)_XCODE_PROJECT)
else ifeq ($(call __exists,$(THEOS_CURRENT_INSTANCE).xcworkspace),$(_THEOS_TRUE))
	_THEOS_XCODEBUILD_PROJECT_FLAG := -workspace $(THEOS_CURRENT_INSTANCE).xcworkspace
else
	_THEOS_XCODEBUILD_PROJECT_FLAG := -project $(THEOS_CURRENT_INSTANCE).xcodeproj
endif

_THEOS_XCODEBUILD_BEGIN = $(ECHO_NOTHING)set -eo pipefail; $(TARGET_XCODEBUILD) \
	$(_THEOS_XCODEBUILD_PROJECT_FLAG) \
	-scheme '$(or $($(THEOS_CURRENT_INSTANCE)_XCODE_SCHEME),$(THEOS_CURRENT_INSTANCE))' \
	-configuration $(_THEOS_XCODE_BUILD_CONFIG)
_THEOS_XCODEBUILD_END = CODE_SIGNING_ALLOWED=NO \
	ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO \
	ENABLE_BITCODE=$(or $($(THEOS_CURRENT_INSTANCE)_ENABLE_BITCODE),NO) \
	DSTROOT=$(THEOS_OBJ_DIR)/install \
	$(_THEOS_XCODE_XCPRETTY)$(ECHO_END)
export EXPANDED_CODE_SIGN_IDENTITY =
export EXPANDED_CODE_SIGN_IDENTITY_NAME =

__theos_find_and_execute = find $(1) -print0 | xargs -I{} -0 bash -c '$(2) "$$@"' _ {};

_THEOS_SIGNABLE_BUNDLE_EXTENSIONS = bundle app framework appex
_THEOS_SIGNABLE_FILE_EXTENSIONS = dylib

internal-xcodeproj-compile:
ifneq ($(_THEOS_PLATFORM_HAS_XCODE),$(_THEOS_TRUE))
	@$(PRINT_FORMAT_ERROR) "The $(THEOS_CURRENT_INSTANCE) target requires Xcode, but the $(THEOS_PLATFORM_NAME) platform does not support Xcode." >&2; \
		exit 1
endif
	$(_THEOS_XCODEBUILD_BEGIN) \
		$(ALL_XCODEOPTS) \
		$(_THEOS_XCODE_BUILD_COMMAND) \
		$(ALL_XCODEFLAGS) \
		$(_THEOS_XCODEBUILD_END)
ifeq ($(_THEOS_PACKAGE_FORMAT),deb)
	$(ECHO_NOTHING)find $(THEOS_OBJ_DIR)/install -name 'libswift*.dylib' -delete$(ECHO_END)
endif
ifneq ($(_THEOS_CODESIGN_COMMANDLINE),)
	$(ECHO_SIGNING)function process_exec { \
		$(_THEOS_CODESIGN_COMMANDLINE) $$1; \
	}; \
	function process_dir { \
		$(call __theos_find_and_execute,"$$1" -mindepth 1 -maxdepth 1 -type d,process_dir) \
		$(foreach ext,$(_THEOS_SIGNABLE_FILE_EXTENSIONS),$(call __theos_find_and_execute,"$$1" -mindepth 1 -maxdepth 1 -name '*.$(ext)',process_exec)) \
		full_dir_name="$$(basename "$$(cd "$$1" && pwd -P)")"; \
		full_dir_ext="$${full_dir_name##*.}"; \
		[[ "$${full_dir_name}" = "$${full_dir_ext}" ]] && full_dir_ext=; \
		for ext in $(_THEOS_SIGNABLE_BUNDLE_EXTENSIONS); do \
			if [[ "$${full_dir_ext}" == "$${ext}" ]]; then \
				process_exec "$$1/$$(/usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" $$1/Info.plist)"; \
				return; \
			fi; \
		done; \
	}; \
	export -f process_exec process_dir; \
	process_dir $(THEOS_OBJ_DIR)/install; \
	$(ECHO_END)
endif

internal-xcodeproj-clean::
	$(_THEOS_XCODEBUILD_BEGIN) \
		$(ALL_XCODEOPTS) \
		clean \
		$(ALL_XCODEFLAGS) \
		$(_THEOS_XCODEBUILD_END)

ifneq ($($(THEOS_CURRENT_INSTANCE)_INSTALL),0)
internal-xcodeproj-stage_::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)"$(ECHO_END)
	$(ECHO_NOTHING)rsync -a $(THEOS_OBJ_DIR)/install/ "$(THEOS_STAGING_DIR)" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE)$(ECHO_END)
endif

$(eval $(call __mod,instance/xcodeproj.mk))
