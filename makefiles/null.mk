ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/null.mk
else
	ifeq ($(FW_TYPE),null)
		include $(FW_MAKEDIR)/instance/null.mk
	endif
endif
