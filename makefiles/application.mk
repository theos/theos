ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/application.mk
else
	ifeq ($(FW_TYPE),application)
		include $(FW_MAKEDIR)/instance/application.mk
	endif
endif
