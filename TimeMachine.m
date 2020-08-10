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
        do_timemachine("/", true);
    }
    if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
        do_timemachine("/private/var", true);
    }

    printf("TimeMachine on iOS's work is down, enjoy safety.\n\n");
    return 0;
}
