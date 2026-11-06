#import <Foundation/Foundation.h>

%hook NSObject
- (id)init {
    return %orig;
}
%end
