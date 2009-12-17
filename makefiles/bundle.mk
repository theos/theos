ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/bundle.mk
else
	ifeq ($(FW_TYPE),bundle)
		include $(FW_MAKEDIR)/instance/bundle.mk
	endif
endif
