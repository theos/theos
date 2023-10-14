ifneq ($(_LOCAL_LINKAGE_TYPE),static)
ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
_THEOS_INTERNAL_LDFLAGS += -install_name "@rpath/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)"
endif
endif
