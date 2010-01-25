ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/library.mk
else
	ifeq ($(FW_TYPE),library)
		include $(FW_MAKEDIR)/instance/library.mk
	endif
endif
