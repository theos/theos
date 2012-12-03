%hook Logging
- (void)charp:(char *)a
       charpp:(char **)b
      charppp:(char ***)c
	 void:(void)d
	voidp:(void*)e
       voidpp:(void **)f
      inttype:(int)g
  unknown_int:(UIInterfaceOrientation)h
    object_id:(id)i
    object_unknown:(NSString *)j
    array_whatever:(void *[])l
	 array_int:(int[32])m
	  array_id:(id[])n
{
	    %log;
}
%end
