#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import "utils.h"

int main() {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
        printf("iOS11 or higher version detected, now checking orig snapshot...\n");
        if (snapshot_check("/", "orig-fs")) {
            printf("Will rename snapshot \"orig-fs\" on fs / to \"com.apple.TimeMachine.orig-fs\"...\n");
            snapshot_rename("/", "orig-fs", "com.apple.TimeMachine.orig-fs");
        }
        if (snapshot_check("/", "electra-prejailbreak")) {
            printf("Will rename snapshot \"electra-prejailbreak\" on fs / to \"com.apple.TimeMachine.electra-prejailbreak\"...\n");
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
    CFDictionaryRef settings = loadPrefs();
    if (settings != NULL) {
        CFDictionaryContainsKey(settings, CFSTR("Hour"));
        if (CFDictionaryContainsKey(settings, CFSTR("Hour"))) {
            CFTypeRef Hour = CFDictionaryGetValue(settings, CFSTR("Hour"));
            if (CFGetTypeID(Hour) == CFNumberGetTypeID()) {
                long hour;
                CFNumberGetValue(Hour, kCFNumberLongType, &hour);
                CFRelease(Hour);
                if (hour < 24) {
                    NSString *plistFile = @"/Library/LaunchDaemons/com.michael.TimeMachine.plist";
                    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFile];
                    plist[@"StartCalendarInterval"][@"Hour"] = @(hour);
                    [[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil] writeToFile:plistFile atomically:YES];
                    goto next;
                }
            }
            CFRelease(Hour);
            CFPreferencesSetValue(CFSTR("Hour"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        }
next:
        if (CFDictionaryContainsKey(settings, CFSTR("Minute"))) {
            CFTypeRef Minute = CFDictionaryGetValue(settings, CFSTR("Minute"));
            if (CFGetTypeID(Minute) == CFNumberGetTypeID()) {
                long minute;
                CFNumberGetValue(Minute, kCFNumberLongType, &minute);
                CFRelease(Minute);
                if (minute < 24) {
                    NSString *plistFile = @"/Library/LaunchDaemons/com.michael.TimeMachine.plist";
                    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFile];
                    plist[@"StartCalendarInterval"][@"Minute"] = @(minute);
                    [[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil] writeToFile:plistFile atomically:YES];
                    goto out;
                }
            }
            CFRelease(Minute);
            CFPreferencesSetValue(CFSTR("Minute"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        }
out:
        CFRelease(settings);
    }

    run_system("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    return 0;
}
