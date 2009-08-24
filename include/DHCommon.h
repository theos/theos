#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Common, useful things.
 * A bit has been lifted from rpetrich's Captain Hook macros. Thanks, Ryan!
 */
#define _Constructor __attribute__((constructor))
#define DHDeclareClass(name) @class name; static Class $ ## name
#define DHLoadLateClass(name) $ ## name = objc_getClass(#name)
#define DHLoadEarlyClass(name) $ ## name = [name class]
#define DHClass(name) $ ## name


static inline void _DHRelease(id object) __attribute__((always_inline));
static inline void _DHRelease(id object) {
	[object release];
}
#define DHScopeReleased __attribute__((cleanup(_DHRelease)))
#define DHScopedAutoreleasePool() NSAutoreleasePool *DHScopedAutoreleasePool __attribute__((cleanup(_DHRelease),unused)) = [[NSAutoreleasePool alloc] init]

// vim:ft=objc
