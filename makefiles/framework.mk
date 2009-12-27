ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/framework.mk
else
	ifeq ($(FW_TYPE),framework)
		include $(FW_MAKEDIR)/instance/framework.mk
	endif
endif
