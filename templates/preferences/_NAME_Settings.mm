#import "_NAME_Settings.h"

@implementation _NAME_SettingsController

- (id)initForContentSize:(CGSize)size {
	if((self = [super initForContentSize:size])) {
		// Initialize!
	}
	return self;
}

- (id)specifiers {
	return [self localizedSpecifiersWithSpecifiers:[self loadSpecifiersFromPlistName:@"_NAME_" target:self]];
}

@end
