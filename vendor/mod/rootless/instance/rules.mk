_THEOS_INTERNAL_LDFLAGS += -rpath $(THEOS_PACKAGE_INSTALL_PREFIX)/Library/Frameworks -rpath $(THEOS_PACKAGE_INSTALL_PREFIX)/usr/lib # v1
_THEOS_INTERNAL_LDFLAGS += -rpath '@loader_path/.jbroot/Library/Frameworks' -rpath '@loader_path/.jbroot/usr/lib' # v2
