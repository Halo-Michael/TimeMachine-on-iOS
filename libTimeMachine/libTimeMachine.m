#import <Foundation/Foundation.h>
#import <removefile.h>
#import <regex.h>
#import "libTimeMachine.h"

NSDictionary *loadPrefs() {
    CFArrayRef keyList = CFPreferencesCopyKeyList(bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
    if (keyList != NULL) {
        return (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost));
    }
    removefile("/private/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", NULL, REMOVEFILE_RECURSIVE);
    CFPreferencesSynchronize(bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
    return nil;
}

bool modifyPlist(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = 0;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) {
        return false;
    }
    if (![data isEqual:newData]) {
        if (![newData writeToFile:filename atomically:YES]) {
            return false;
        }
    }
    return true;
}

CFNumberRef newInt(int value) {
    return CFNumberCreate(NULL, kCFNumberIntType, &value);
}
