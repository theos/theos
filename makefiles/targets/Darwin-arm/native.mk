ifeq ($(FW_TARGET_LOADED),)
INSTALL_LOCAL := 1
include $(FW_MAKEDIR)/targets/Darwin-arm/iphone.mk
endif
