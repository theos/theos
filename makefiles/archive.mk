ifeq ($(THEOS_CURRENT_INSTANCE),)
	include $(THEOS_MAKE_PATH)/master/archive.mk
else
	ifeq ($(_THEOS_CURRENT_TYPE),archive)
		include $(THEOS_MAKE_PATH)/instance/archive.mk
	endif
endif
