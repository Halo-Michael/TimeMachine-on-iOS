#include <CoreFoundation/CoreFoundation.h>
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

    run_system("chown root:wheel /etc/rc.d/snapshotcheck");
    run_system("chmod 6755 /etc/rc.d/snapshotcheck");
    run_system("chown root:wheel /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    run_system("chown root:wheel /usr/libexec/TimeMachine");
    run_system("chmod 6755 /usr/libexec/TimeMachine");
    run_system("chown root:wheel /usr/bin/setTimeMachine");
    run_system("chmod 6755 /usr/bin/setTimeMachine");
    run_system("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    return 0;
}
