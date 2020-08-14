#import <Foundation/Foundation.h>
#import "utils.h"

void usage() {
    printf("Usage:\tsetTimeMachine [OPTIONS...]\n");
    printf("\t-h\tPrint this help.\n");
    printf("\t-f <vol> [--enable | --disable] [--n <number>]\n");
    printf("\t\tSet a way to backup snapshots for specify filesystem.\n");
    printf("\t-s\tShow current settings.\n");
    printf("\t-t [--h <hour>] [--m <minute>]\n");
    printf("\t\tSet a time to backup snapshots(24-hour system).\n");
}

void showSettings() {
    NSDictionary *launchdSettings = [NSDictionary dictionaryWithContentsOfFile:@"/Library/LaunchDaemons/com.michael.TimeMachine.plist"];
    printf("Will backup snapshots at %d:%d.\n", [launchdSettings[@"StartCalendarInterval"][@"Hour"] intValue], [launchdSettings[@"StartCalendarInterval"][@"Minute"] intValue]);
    NSDictionary *settings = loadPrefs();
    int max_rootfs_snapshot = 3, max_datafs_snapshot = 3;
    if (settings[@"rootfs_enabled"] == nil || [settings[@"rootfs_enabled"] boolValue]) {
        printf("TimeMachine for rootfs is enabled.\n");
    } else {
        printf("TimeMachine for rootfs is disabled.\n");
    }
    if (settings[@"max_rootfs_snapshot"]) {
        if (is_number([[NSString stringWithFormat:@"%@", settings[@"max_rootfs_snapshot"]] UTF8String])) {
            max_rootfs_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
            if (max_rootfs_snapshot != 0) {
                printf("Will save up to %d snapshots for rootfs\n", max_rootfs_snapshot);
            } else {
                printf("Won't save snapshot for rootfs\n");
            }
        } else {
            CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), NULL, bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
        }
    } else {
        printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
    }
    if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
        printf("TimeMachine for datafs is enabled.\n");
    } else {
        printf("TimeMachine for datafs is disabled.\n");
    }
    if (settings[@"max_datafs_snapshot"]) {
        if (is_number([[NSString stringWithFormat:@"%@", settings[@"max_datafs_snapshot"]] UTF8String])) {
            max_datafs_snapshot = [settings[@"max_datafs_snapshot"] intValue];
            if (max_datafs_snapshot != 0) {
                printf("Will save up to %d snapshots for datafs\n", max_datafs_snapshot);
            } else {
                printf("Won't save snapshot for datafs\n");
            }
        } else {
            CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), NULL, bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
        }
    } else {
        printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
    }
}

int f(const int argc, const char *argv[], NSArray *args) {
    NSString *filePath = nil, *number = nil;
    if ([args count] > ([args indexOfObject:@"-f"] + 1)) {
        filePath = args[([args indexOfObject:@"-f"] + 1)];
    } else {
        usage();
        return 1;
    }
    if ([args containsObject:@"--n"]) {
        if ([args count] > ([args indexOfObject:@"--n"] + 1) && is_number([args[([args indexOfObject:@"--n"] + 1)] UTF8String])) {
            number = args[([args indexOfObject:@"--n"] + 1)];
        } else {
            usage();
            return 1;
        }
    }

    if (number == nil && ![args containsObject:@"--enable"] && ![args containsObject:@"--disable"]) {
        usage();
        return 1;
    }

    while ([filePath characterAtIndex:([[NSNumber numberWithUnsignedInteger:[filePath length]] intValue] - 1)] == '/' && [[NSNumber numberWithUnsignedInteger:[filePath length]] intValue] != 1) {
        filePath = [filePath substringToIndex:([[NSNumber numberWithUnsignedInteger:[filePath length]] intValue] - 1)];
    }
    NSError *error = nil;
    NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error]];
    if (error) {
        usage();
        return 1;
    }
    if ([fileInfo[@"NSFileType"] isEqualToString:@"NSFileTypeSymbolicLink"]) {
        char realPath[2048];
        realpath([filePath UTF8String], realPath);
        if (strlen(realPath) == 0) {
            usage();
            return 2;
        }
        filePath = [NSString stringWithFormat:@"%s", realPath];
        fileInfo = [NSMutableDictionary dictionaryWithDictionary:[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error]];
        if (error) {
            usage();
            return 2;
        }
    }
    if (![fileInfo[@"NSFileType"] isEqualToString:@"NSFileTypeDirectory"]) {
        usage();
        return 3;
    }
    if ([filePath isEqualToString:@"/"]) {
        if ([args containsObject:@"--enable"]) {
            printf("Will enable TimeMachine for rootfs.\n");
            CFPreferencesSetValue(CFSTR("rootfs_enabled"), kCFBooleanTrue, bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
        } else if ([args containsObject:@"--disable"]) {
            printf("Will disable TimeMachine for rootfs.\n");
            CFPreferencesSetValue(CFSTR("rootfs_enabled"), kCFBooleanFalse, bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
        }
        if (number != nil) {
            CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), newInt([number intValue]), bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("Successfully set TimeMachine to backup up to most %s snapshots for rootfs.\n", [number UTF8String]);
            NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist"];
            if (settings[@"rootfs_enabled"] == nil || [settings[@"rootfs_enabled"] boolValue]) {
                printf("Now delete the extra snapshot.\n");
                if (do_timemachine("/", false) == 0) {
                    printf("Successfully delete the extra snapshot.\n");
                } else {
                    printf("There is nothing to do.\n");
                }
            } else {
                printf("TimeMachine for rootfs is disabled.\n");
            }
        }
    } else if ([filePath isEqualToString:@"/private/var"]) {
        if ([args containsObject:@"--enable"]) {
            printf("Will enable TimeMachine for datafs.\n");
            CFPreferencesSetValue(CFSTR("datafs_enabled"), kCFBooleanTrue, bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
        } else if ([args containsObject:@"--disable"]) {
            printf("Will disable TimeMachine for datafs.\n");
            CFPreferencesSetValue(CFSTR("datafs_enabled"), kCFBooleanFalse, bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
        }
        if (number != nil) {
            CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), newInt([number intValue]), bundleID(), CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("Successfully set TimeMachine to backup up to most %s snapshots for datafs.\n", [number UTF8String]);
            NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist"];
            if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
                printf("Now delete the extra snapshot.\n");
                if (do_timemachine("/private/var", false) == 0) {
                    printf("Successfully delete the extra snapshot.\n");
                } else {
                    printf("There is nothing to do.\n");
                }
            } else {
                printf("TimeMachine for datafs is disabled.\n");
            }
        }
    } else {
        usage();
        return 1;
    }
    return 0;
}

int t(const int argc, const char *argv[], NSArray *args) {
    NSString *hour = nil, *minute = nil;
    if ([args containsObject:@"--hour"] || [args containsObject:@"--minute"]) {
        if ([args count] > ([args indexOfObject:@"--hour"] + 1) && is_number([args[([args indexOfObject:@"--hour"] + 1)] UTF8String]) && [args[([args indexOfObject:@"--hour"] + 1)] intValue] < 24) {
            hour = args[([args indexOfObject:@"--hour"] + 1)];
        }
        if ([args count] > ([args indexOfObject:@"--minute"] + 1) && is_number([args[([args indexOfObject:@"--minute"] + 1)] UTF8String]) && [args[([args indexOfObject:@"--minute"] + 1)] intValue] < 60) {
            minute = args[([args indexOfObject:@"--minute"] + 1)];
        }
    } else {
        usage();
        return 1;
    }
    if (hour == nil && minute == nil) {
        usage();
        return 1;
    }
    NSString *launchdPlist = @"/Library/LaunchDaemons/com.michael.TimeMachine.plist";
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:launchdPlist];
    if (hour == nil) {
        hour = [NSString stringWithFormat:@"%@", settings[@"StartCalendarInterval"][@"Hour"]];
    } else if (minute == nil) {
        minute = [NSString stringWithFormat:@"%@", settings[@"StartCalendarInterval"][@"Minute"]];
    }
    printf("Will modify time to %s:%s.\n", [hour UTF8String], [minute UTF8String]);
    run_system("launchctl unload /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    modifyPlist(launchdPlist, ^(id plist) {
        plist[@"StartCalendarInterval"][@"Hour"] = @([hour integerValue]);
    });
    modifyPlist(launchdPlist, ^(id plist) {
        plist[@"StartCalendarInterval"][@"Minute"] = @([minute integerValue]);
    });
    run_system("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");

    return 0;
}

int main(const int argc, const char *argv[]) {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }

    NSMutableArray *args = [NSMutableArray array];
    for (int i = 1; i < argc; i++) {
        [args addObject:[[NSString alloc] initWithUTF8String:argv[i]]];
    }
    
    if ([args containsObject:@"-h"]) {
        usage();
        return 0;
    }
    if ([args containsObject:@"-s"]) {
        showSettings();
        return 0;
    }
    if ([args containsObject:@"-f"] || [args containsObject:@"-t"]) {
        int status;
        if ([args containsObject:@"-f"]) {
            status = f(argc, argv, args);
            if (status != 0) {
                return status;
            }
        }
        if ([args containsObject:@"-t"]) {
            status = t(argc, argv, args);
            if (status != 0) {
                return status;
            }
        }
    } else {
        usage();
        return 1;
    }
    printf("Now exit.\n");
    return 0;
}
