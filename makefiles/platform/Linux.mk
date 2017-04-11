ifeq ($(_THEOS_PLATFORM_LOADED),)
_THEOS_PLATFORM_LOADED := 1
THEOS_PLATFORM_NAME := linux

_THEOS_PLATFORM_DEFAULT_TARGET := iphone
_THEOS_PLATFORM_DU_EXCLUDE := --exclude
_THEOS_PLATFORM_MD5SUM := md5sum
# TODO: Find some better way to determine _THEOS_PLATFORM_SHOW_IN_FILE_MANAGER, as not all desktop environments use Nautilus as the file manager
_THEOS_PLATFORM_SHOW_IN_FILE_MANAGER := nautilus
_THEOS_PLATFORM_GET_LOGICAL_CORES := nproc
endif
