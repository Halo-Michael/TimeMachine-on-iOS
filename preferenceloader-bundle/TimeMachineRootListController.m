#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface TimeMachineRootListController : PSListController

@end

@implementation TimeMachineRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];

    if([specifier.properties[@"key"] isEqualToString:@"max_rootfs_snapshot"]) {
        system([[NSString stringWithFormat:@"setTimeMachine -f / -n %@", value] UTF8String]);
    }

    if([specifier.properties[@"key"] isEqualToString:@"max_datafs_snapshot"]) {
        system([[NSString stringWithFormat:@"setTimeMachine -f /var -n %@", value] UTF8String]);
    }
}

@end
