ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/tweak.mk
else
	ifeq ($(FW_TYPE),tweak)
		include $(FW_MAKEDIR)/instance/tweak.mk
	endif
endif
