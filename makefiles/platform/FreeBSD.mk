ifeq ($(_THEOS_PLATFORM_LOADED),)
_THEOS_PLATFORM_LOADED := 1
THEOS_PLATFORM_NAME := freebsd

_THEOS_PLATFORM_DEFAULT_TARGET := iphone
_THEOS_PLATFORM_DU_EXCLUDE := -I
_THEOS_PLATFORM_MD5SUM := md5

# TODO: Find some better way to determine _THEOS_PLATFORM_SHOW_IN_FILE_MANAGER, as not all desktop
# environments use Nautilus as the file manager
_THEOS_PLATFORM_SHOW_IN_FILE_MANAGER := nautilus

_THEOS_PLATFORM_GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
