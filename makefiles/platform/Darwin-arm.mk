ifeq ($(_THEOS_PLATFORM_LOADED),)
_THEOS_PLATFORM_LOADED := 1
THEOS_PLATFORM_NAME := iphone

_THEOS_PLATFORM_DEFAULT_TARGET := iphone

# Default to dpkg-deb, but use dm.pl if set up properly.
_THEOS_PLATFORM_DPKG_DEB := dpkg-deb

ifeq ($(call __executable,dm.pl),$(_THEOS_TRUE))
ifeq ($(shell perl -MIO::Compress::Lzma -MCompress::Raw::Lzma -e 'print 1' 2>/dev/null),1)
_THEOS_PLATFORM_DPKG_DEB := dm.pl
endif
endif

_THEOS_PLATFORM_DU_EXCLUDE := --exclude
_THEOS_PLATFORM_MD5SUM := md5sum
_THEOS_PLATFORM_LIPO = lipo
_THEOS_PLATFORM_GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
