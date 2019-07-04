ifeq ($(THEOS_CURRENT_INSTANCE),)
	include $(THEOS_MAKE_PATH)/master/xcodeproj.mk
else
	ifeq ($(_THEOS_CURRENT_TYPE),xcodeproj)
		include $(THEOS_MAKE_PATH)/instance/xcodeproj.mk
	endif
endif
