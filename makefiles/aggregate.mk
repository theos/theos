ifeq ($(FW_AGGREGATE_MK_LOADED),)
	FW_AGGREGATE_MK_LOADED := 1

	ifeq ($(FW_INSTANCE),)
		include $(FW_MAKEDIR)/master/aggregate.mk
	endif
endif
