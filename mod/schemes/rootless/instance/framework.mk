ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
_THEOS_INTERNAL_LDFLAGS += -dynamiclib -install_name "@rpath/$(_LOCAL_INSTANCE_TARGET)"
endif
