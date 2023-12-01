ifneq ($(_LOCAL_LINKAGE_TYPE),static)
_THEOS_INTERNAL_LDFLAGS += -install_name "@rpath/$(THEOS_CURRENT_INSTANCE)$(TARGET_LIB_EXT)"
endif
