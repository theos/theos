#import <DHLocalizedListController.h>

@implementation DHLocalizedListController

- (id)navigationTitle {
	return [[self bundle] localizedStringForKey:_title value:_title table:nil];
}

- (id)localizedSpecifiersWithSpecifiers:(NSArray *)specifiers {
	int i;
	for(PSSpecifier *curSpec in specifiers) {
		NSString *name = [curSpec name];
		if(name) {
			[curSpec setName:[[self bundle] localizedStringForKey:name value:name table:nil]];
		}
		id titleDict = [curSpec titleDictionary];
		if(titleDict) {
			NSMutableDictionary *newTitles = [[NSMutableDictionary alloc] init];
			for(NSString *key in titleDict) {
				NSString *value = [titleDict objectForKey:key];
				[newTitles setObject:[[self bundle] localizedStringForKey:value value:value table:nil] forKey: key];
			}
			[curSpec setTitleDictionary: [newTitles autorelease]];
		}
	}
	return specifiers;
}

@end
