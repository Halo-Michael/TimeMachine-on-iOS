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
#import "common.h"

@interface SKPersonCell : PSTableCell {
    UIImageView *_background;
    UILabel *label;
    UILabel *label2;
    UIButton *twitterButton;
}

-(NSString*)personDescription;
-(NSString*)imageName;
-(NSString*)name;
-(NSString*)twitterHandle;

-(void)updateImage;
-(NSString*)localizedString:(NSString*)string;
@end
