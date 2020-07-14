#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "../utils.h"

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
    if ([[specifier propertyForKey:@"key"] isEqualToString:@"max_rootfs_snapshot"]) {
        run_system([[NSString stringWithFormat:@"setTimeMachine -f / --n %@", value] UTF8String]);
    }
    if ([[specifier propertyForKey:@"key"] isEqualToString:@"max_datafs_snapshot"]) {
        run_system([[NSString stringWithFormat:@"setTimeMachine -f /private/var --n %@", value] UTF8String]);
    }
    if ([[specifier propertyForKey:@"key"] isEqualToString:@"Hour"]) {
        run_system([[NSString stringWithFormat:@"setTimeMachine -t --hour %@", value] UTF8String]);
    }
    if ([[specifier propertyForKey:@"key"] isEqualToString:@"Minute"]) {
        run_system([[NSString stringWithFormat:@"setTimeMachine -t --minute %@", value] UTF8String]);
    }
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
    if ([[specifier propertyForKey:@"key"] isEqualToString:@"Hour"]) {
        return [NSDictionary dictionaryWithContentsOfFile:@"/Library/LaunchDaemons/com.michael.TimeMachine.plist"][@"StartCalendarInterval"][@"Hour"];
    }
    if ([[specifier propertyForKey:@"key"] isEqualToString:@"Minute"]) {
        return [NSDictionary dictionaryWithContentsOfFile:@"/Library/LaunchDaemons/com.michael.TimeMachine.plist"][@"StartCalendarInterval"][@"Minute"];
    }
    return [super readPreferenceValue:specifier];
}

@end
