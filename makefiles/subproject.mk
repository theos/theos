ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/subproject.mk
else
	ifeq ($(FW_TYPE),subproject)
		include $(FW_MAKEDIR)/instance/subproject.mk
	endif
endif
