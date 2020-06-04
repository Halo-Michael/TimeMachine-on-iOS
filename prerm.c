#include <CoreFoundation/CoreFoundation.h>
#include <sys/snapshot.h>
#include "utils.h"

int main(int argc, const char **argv) {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    run_system("launchctl unload /Library/LaunchDaemons/com.michael.TimeMachine.plist");

    if (strcmp(argv[1], "upgrade") == 0) {
        return 0;
    }

    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
        printf("iOS11 or higher version detected, now checking orig snapshot...\n");
        if (snapshot_check("/", "com.apple.TimeMachine.orig-fs") == 1) {
            printf("Will rename snapshot \"com.apple.TimeMachine.orig-fs\" on fs / to \"orig-fs\"\n");
            snapshot_rename("/", "com.apple.TimeMachine.orig-fs", "orig-fs");
        }
        if (snapshot_check("/", "com.apple.TimeMachine.electra-prejailbreak") == 1) {
            printf("Will rename snapshot \"com.apple.TimeMachine.electra-prejailbreak\" on fs / to \"electra-prejailbreak\"\n");
            snapshot_rename("/", "com.apple.TimeMachine.electra-prejailbreak", "electra-prejailbreak");
        }
    } else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3) {
        printf("iOS10 detected, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 1;
    }
    return 0;
}
