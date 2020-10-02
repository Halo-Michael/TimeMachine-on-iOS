#import <Foundation/Foundation.h>
#import "utils.h"

int main() {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }

    run_system("/etc/rc.d/snapshotcheck");

    NSDictionary *settings = loadPrefs();

    if (settings[@"rootfs_enabled"] == nil || [settings[@"rootfs_enabled"] boolValue]) {
        int max_snapshot = 3;
        if (settings[@"max_rootfs_snapshot"]) {
            if (is_number([[NSString stringWithFormat:@"%@", settings[@"max_rootfs_snapshot"]] UTF8String])) {
                max_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
            } else {
                CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            }
        }
        do_timemachine("/", true, max_snapshot);
    }
    if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
        int max_snapshot = 3;
        if (settings[@"max_datafs_snapshot"]) {
            if (is_number([[NSString stringWithFormat:@"%@", settings[@"max_datafs_snapshot"]] UTF8String])) {
                max_snapshot = [settings[@"max_datafs_snapshot"] intValue];
            } else {
                CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            }
        }
        do_timemachine("/private/var", true, max_snapshot);
    }

    printf("TimeMachine on iOS's work is down, enjoy safety.\n\n");
    return 0;
}
