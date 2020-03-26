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
#import "SKTintedListController.h"
#import "SKListControllerProtocol.h"
#import <MessageUI/MFMailComposeViewController.h>

// Assumes localization.

@interface SKStandardController : SKTintedListController<SKListControllerProtocol, MFMailComposeViewControllerDelegate>
-(NSString*) postNotification;
-(NSString*) defaultsFileName;
-(NSString*) enabledDescription;

-(NSArray*) emailAddresses;
-(NSString*) emailBody;
-(NSString*) emailSubject;

//-(void) loadSettingsListController;
//-(void) loadMakersListController;
-(void) showSupportDialog;

-(NSString*) settingsListControllerClassName;
-(NSString*) makersListControllerClassName;

-(NSString*) footerText;

-(UIColor*) iconColor;
@end
