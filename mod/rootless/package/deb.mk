ifeq ($(THEOS_PACKAGE_SCHEME)-$(THEOS_PACKAGE_ARCH),rootless-iphoneos-arm)
	# Override architecture
	THEOS_PACKAGE_ARCH := iphoneos-arm64
endif
