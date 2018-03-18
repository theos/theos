# Variables that are common to all Darwin-based targets.
TARGET_EXE_EXT :=
TARGET_LIB_EXT := .dylib

TARGET_LDFLAGS_DYNAMICLIB = -dynamiclib -install_name "$(LOCAL_INSTALL_PATH)/$(1)"
TARGET_CFLAGS_DYNAMICLIB = 

_THEOS_TARGET_ONLY_OBJCFLAGS := -std=c99

_THEOS_TARGET_SUPPORTS_BUNDLES := 1
