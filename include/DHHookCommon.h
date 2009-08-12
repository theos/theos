#import <substrate.h>

#define HOOK(class, name, type, args...) \
	static type (*_ ## class ## $ ## name)(class *self, SEL sel, ## args); \
	static type $ ## class ## $ ## name(class *self, SEL sel, ## args)

#define CALL_ORIG(class, name, args...) \
	_ ## class ## $ ## name(self, sel, ## args)

#define GET_CLASS(class) \
	Class $ ## class = objc_getClass(#class)

#define HOOK_MESSAGE(class, sel) \
	_ ## class ## $ ## sel = MSHookMessage($ ## class, @selector(sel), &$ ## class ## $ ## sel) 

static inline SEL __getsel(const char *in) {
	int len = strlen(in) + 1;
	char selector[len];
	for(int i = 0; i < len; i++)
		selector[i] = (in[i] == '$' ? ':' : in[i]);
	return sel_getUid(selector);
}
#define HOOK_MESSAGE_AUTO(class, sel) \
	_ ## class ## $ ## sel = MSHookMessage($ ## class, __getsel(#sel), &$ ## class ## $ ## sel)

#define HOOK_MESSAGE_REPLACEMENT(class, sel, replace) \
	_ ## class ## $ ## replace = MSHookMessage($ ## class, @selector(sel), &$ ## class ## $ ## replace)

#define HOOK_MESSAGE_ARGS HOOK_MESSAGE_WITH_SINGLE_ARG
#define HOOK_MESSAGE_EX HOOK_MESSAGE_AUTO
#define HOOK_MESSAGE_F HOOK_MESSAGE_REPLACEMENT

#define DHGetClass GET_CLASS
#define DHHookMessageWithReplacement HOOK_MESSAGE_REPLACEMENT
#define DHHookMessageWithAutoRename HOOK_MESSAGE_AUTO
