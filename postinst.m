#import <Foundation/Foundation.h>
#include <sys/stat.h>
#include "utils.h"

int main() {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
        printf("iOS11 or higher version detected, now checking orig snapshot...\n");
        if (snapshot_check("/", "orig-fs") == 1) {
            printf("Will rename snapshot \"orig-fs\" on fs / to \"com.apple.TimeMachine.orig-fs\"\n");
            snapshot_rename("/", "orig-fs", "com.apple.TimeMachine.orig-fs");
        }
        if (snapshot_check("/", "electra-prejailbreak") == 1) {
            printf("Will rename snapshot \"electra-prejailbreak\" on fs / to \"com.apple.TimeMachine.electra-prejailbreak\"\n");
            snapshot_rename("/", "electra-prejailbreak", "com.apple.TimeMachine.electra-prejailbreak");
        }
    } else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3) {
        printf("iOS10 detected, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 1;
    }

    chown("/etc/rc.d/snapshotcheck", 0, 0);
    chmod("/etc/rc.d/snapshotcheck", 06755);
    chown("/Library/LaunchDaemons/com.michael.TimeMachine.plist", 0, 0);
    chown("/usr/libexec/TimeMachine", 0, 0);
    chmod("/usr/libexec/TimeMachine", 06755);
    chown("/usr/bin/setTimeMachine", 0, 0);
    chmod("/usr/bin/setTimeMachine", 06755);

    NSString *const settingsPlist = @"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist";
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:settingsPlist];
    NSString *launchdPlist = @"/Library/LaunchDaemons/com.michael.TimeMachine.plist";
    bool isDirectory;
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist" isDirectory:&isDirectory]) {
        if (isDirectory) {
            remove("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        } else {
            NSString *hour = [NSString stringWithFormat:@"%@", settings[@"Hour"]];
            NSString *minute = [NSString stringWithFormat:@"%@", settings[@"Minute"]];
            if (hour != nil) {
                if (is_number([hour UTF8String]) && [hour intValue] < 24) {
                    modifyPlist(launchdPlist, ^(id plist) {
                        plist[@"StartCalendarInterval"][@"Hour"] = @([hour integerValue]);
                    });
                } else {
                    modifyPlist(settingsPlist, ^(id plist) {
                        plist[@"Hour"] = nil;
                    });
                }
            }
            if (minute != nil) {
                if (is_number([minute UTF8String]) && [minute intValue] < 60) {
                    modifyPlist(launchdPlist, ^(id plist) {
                        plist[@"StartCalendarInterval"][@"Minute"] = @([minute integerValue]);
                    });
                } else {
                    modifyPlist(settingsPlist, ^(id plist) {
                        plist[@"Minute"] = nil;
                    });
                }
            }
        }
    }

    run_system("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    return 0;
}