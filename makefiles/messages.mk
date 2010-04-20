ifneq ($(messages),yes)
	ECHO_COMPILING = @(echo " Compiling $<...";
	ECHO_LINKING = @(echo " Linking $(FW_TYPE) $(FW_INSTANCE)...";
	ECHO_STRIPPING = @(echo " Stripping $(FW_INSTANCE)...";
	ECHO_SIGNING = @(echo " Signing $(FW_INSTANCE)...";
	ECHO_LOGOS = @(echo " Preprocessing $<...";
	ECHO_COPYING_RESOURCE_FILES = @(echo " Copying resource files into the $(FW_TYPE) wrapper...";
	ECHO_COPYING_RESOURCE_DIRS = @(echo " Copying resource directories into the $(FW_TYPE) wrapper...";
	ECHO_NOTHING = @(

	ECHO_END = )
else
	ECHO_COMPILING =
	ECHO_LINKING = 
	ECHO_STRIPPING = 
	ECHO_SIGNING = 
	ECHO_LOGOS = 
	ECHO_COPYING_RESOURCE_FILES =
	ECHO_COPYING_RESOURCE_DIRS =
	ECHO_NOTHING = 
	ECHO_END = 
endif
