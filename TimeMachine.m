#import <Foundation/Foundation.h>
#import <removefile.h>
#import <sys/snapshot.h>
#import "utils.h"

int do_timemachine(const char *vol) {
    NSDictionary *settings = loadPrefs();
    int max_snapshot = 3;
    if (strcmp(vol, "/") == 0) {
        if (settings[@"max_rootfs_snapshot"]) {
            if (is_number([[NSString stringWithFormat:@"%@", settings[@"max_rootfs_snapshot"]] UTF8String])) {
                max_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
            } else {
                CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            }
        }
    } else if (strcmp(vol, "/private/var") == 0) {
        if (settings[@"max_datafs_snapshot"]) {
            if (is_number([[NSString stringWithFormat:@"%@", settings[@"max_datafs_snapshot"]] UTF8String])) {
                max_snapshot = [settings[@"max_datafs_snapshot"] intValue];
            } else {
                CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            }
        }
    } else {
        perror("what?");
        exit(1);
    }

    if (max_snapshot != 0) {
        time_t time_T = time(NULL);
        struct tm *tmTime = localtime(&time_T);
        char* format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
        char cre_snapshot[42];
        strftime(cre_snapshot, sizeof(cre_snapshot), format, tmTime);
        printf("Will create snapshot named \"%s\" on fs \"%s\"...\n", cre_snapshot, vol);
        removefile("/.com.michael.TimeMachine", NULL, REMOVEFILE_RECURSIVE);
        FILE *fp = fopen("/.com.michael.TimeMachine", "w");
        fprintf(fp, "%s", cre_snapshot);
        fclose(fp);
        snapshot_create(vol, cre_snapshot);
        removefile("/.com.michael.TimeMachine", NULL, REMOVEFILE_RECURSIVE);
    }

    NSMutableArray *snapshots = copy_snapshot_list(vol);

    if ([snapshots count] > max_snapshot) {
        while ([snapshots count] > max_snapshot) {
            printf("Will delete snapshot named \"%s\" on fs \"%s\"...\n", [[snapshots objectAtIndex:0] UTF8String], vol);
            snapshot_delete(vol, [[snapshots objectAtIndex:0] UTF8String]);
            [snapshots removeObjectAtIndex:0];
        }
    } else {
        return 1;
    }
    return 0;
}

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
        do_timemachine("/");
    }
    if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
        do_timemachine("/private/var");
    }

    printf("TimeMachine on iOS's work is down, enjoy safety.\n\n");
    return 0;
}
