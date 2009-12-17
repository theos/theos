ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/tool.mk
else
	ifeq ($(FW_TYPE),tool)
		include $(FW_MAKEDIR)/instance/tool.mk
	endif
endif
