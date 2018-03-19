ifeq ($(_THEOS_PLATFORM_LOADED),)
_THEOS_PLATFORM_LOADED := 1
THEOS_PLATFORM_NAME := iphone

_THEOS_PLATFORM_DEFAULT_TARGET := iphone
_THEOS_PLATFORM_DPKG_DEB := $(shell \
	PATH=$$PATH:$(THEOS_BIN_PATH); \
	DM=$$(which dm.pl); \
	[ ! -z "$${DM}" ] && $(PERL) -MIO::Compress::Lzma -MIO::Compress::Gzip -MIO::Compress::Bzip2 -MIO::Compress::Xz -e 'exit 0' \
		&& echo $$DM || echo dpkg-deb \
	)
_THEOS_PLATFORM_DU_EXCLUDE := --exclude
_THEOS_PLATFORM_MD5SUM := md5sum
_THEOS_PLATFORM_LIPO = lipo
_THEOS_PLATFORM_GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
