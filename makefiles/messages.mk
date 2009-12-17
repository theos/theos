ifneq ($(messages),yes)
	ECHO_COMPILING = @(echo " Compiling $<...";
	ECHO_LINKING = @(echo " Linking $(FW_TYPE) $(FW_INSTANCE)...";
	ECHO_STRIPPING = @(echo " Stripping $(FW_INSTANCE)...";
	ECHO_SIGNING = @(echo " Signing $(FW_INSTANCE)...";
	ECHO_NOTHING = @(

	ECHO_END = )
else
	ECHO_COMPILING =
	ECHO_LINKING = 
	ECHO_STRIPPING = 
	ECHO_SIGNING = 
	ECHO_NOTHING = 
	ECHO_END = 
endif
