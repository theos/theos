#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface DHLocalizedListController : PSListController {
}
- (id)navigationTitle;
- (id)localizedSpecifiersWithSpecifiers:(NSArray *)specifiers;
@end
