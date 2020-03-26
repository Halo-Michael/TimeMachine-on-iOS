#import <Preferences/PSBundleController.h>
#import <Preferences/PSControlTableCell.h>
#import <Preferences/PSDiscreteSlider.h>
#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSHeaderFooterView.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <Preferences/PSRootController.h>
#import <Preferences/PSSliderTableCell.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PSSystemPolicyForApp.h>
#import <Preferences/PSTableCell.h>
#import <Preferences/PSViewController.h>
#import <Preferences/PreferencesAppController.h>
#import "SKListControllerProtocol.h"
#import "common.h"

@interface SKTintedListController : PSListController<SKListControllerProtocol>
- (id)localizedSpecifiersWithSpecifiers:(NSArray *)specifiers;
-(NSString*)localizedString:(NSString*)string;
@end
