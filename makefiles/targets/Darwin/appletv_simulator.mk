ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := appletvos_simulator

_THEOS_TARGET_PLATFORM_NAME := appletvos
_THEOS_TARGET_PLATFORM_SDK_NAME := AppleTVSimulator
_THEOS_TARGET_PLATFORM_FLAG_NAME := tvos-simulator
_THEOS_TARGET_PLATFORM_SWIFT_NAME := apple-tvos
_THEOS_TARGET_PLATFORM_IS_SIMULATOR := $(_THEOS_TRUE)
_THEOS_DARWIN_CAN_USE_MODULES := $(_THEOS_TRUE)

NEUTRAL_ARCH := x86_64

_THEOS_TARGET_DEFAULT_OS_DEPLOYMENT_VERSION := 9.0

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk

ifeq ($(APPLETV_SIMULATOR_ROOT),)
internal-install::
	$(ERROR_BEGIN)"$(MAKE) install for the simulator requires that you set APPLETV_SIMULATOR_ROOT to the root directory of the simulated OS."$(ERROR_END)
else
ifneq ($(call __validate,$(APPLETV_SIMULATOR_ROOT)),$(_THEOS_TRUE))
$(ERROR_BEGIN)"$(APPLETV_SIMULATOR_ROOT) contains spaces or does not exist."$(ERROR_END)
endif
internal-install:: stage
	$(ECHO_NOTHING)install.mergeDir "$(THEOS_STAGING_DIR)" "$(APPLETV_SIMULATOR_ROOT)"$(ECHO_END)
endif

_TARGET_OBJC_ABI_CFLAGS = -fobjc-abi-version=2 -fobjc-legacy-dispatch
_TARGET_OBJC_ABI_LDFLAGS = -Xlinker -objc_abi_version -Xlinker 2 -Xlinker -allow_simulator_linking_to_macosx_dylibs

_THEOS_TARGET_CFLAGS += $(_TARGET_OBJC_ABI_CFLAGS)
_THEOS_TARGET_LDFLAGS += $(_TARGET_OBJC_ABI_LDFLAGS)
endif
