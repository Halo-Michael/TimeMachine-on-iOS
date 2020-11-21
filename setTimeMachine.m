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
    CFDictionaryRef settings = loadPrefs();
    if (settings == NULL) {
        settings = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
    }
    int max_rootfs_snapshot = 3, max_datafs_snapshot = 3;
    if (!CFDictionaryContainsKey(settings, CFSTR("rootfs_enabled")) || CFBooleanGetValue(CFDictionaryGetValue(settings, CFSTR("rootfs_enabled")))) {
        printf("TimeMachine for rootfs is enabled.\n");
    } else {
        printf("TimeMachine for rootfs is disabled.\n");
    }
    if (CFDictionaryContainsKey(settings, CFSTR("max_rootfs_snapshot"))) {
        CFTypeRef num = CFDictionaryGetValue(settings, CFSTR("max_rootfs_snapshot"));
        if (CFGetTypeID(num) == CFNumberGetTypeID()) {
            CFNumberGetValue(num, kCFNumberIntType, &max_rootfs_snapshot);
            if (max_rootfs_snapshot != 0) {
                printf("Will save up to %d snapshots for rootfs\n", max_rootfs_snapshot);
            } else {
                printf("Won't save snapshot for rootfs\n");
            }
        } else {
            CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
        }
        CFRelease(num);
    } else {
        printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
    }
    if (!CFDictionaryContainsKey(settings, CFSTR("datafs_enabled")) || CFBooleanGetValue(CFDictionaryGetValue(settings, CFSTR("datafs_enabled")))) {
        printf("TimeMachine for datafs is enabled.\n");
    } else {
        printf("TimeMachine for datafs is disabled.\n");
    }
    if (CFDictionaryContainsKey(settings, CFSTR("max_datafs_snapshot"))) {
        CFTypeRef num = CFDictionaryGetValue(settings, CFSTR("max_datafs_snapshot"));
        if (CFGetTypeID(num) == CFNumberGetTypeID()) {
            CFNumberGetValue(num, kCFNumberIntType, &max_datafs_snapshot);
            if (max_datafs_snapshot != 0) {
                printf("Will save up to %d snapshots for datafs\n", max_datafs_snapshot);
            } else {
                printf("Won't save snapshot for datafs\n");
            }
        } else {
            CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
        }
        CFRelease(num);
    } else {
        printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
    }
    CFRelease(settings);
}

int f(NSArray *args) {
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
        char *realPath = (char *)calloc(MAXPATHLEN, sizeof(char));
        realpath([filePath UTF8String], realPath);
        if (strlen(realPath) == 0) {
            usage();
            return 2;
        }
        realPath = (char *)realloc(realPath, (strlen(realPath) + 1) * sizeof(char));
        filePath = [NSString stringWithFormat:@"%s", realPath];
        free(realPath);
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
            CFPreferencesSetValue(CFSTR("rootfs_enabled"), kCFBooleanTrue, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        } else if ([args containsObject:@"--disable"]) {
            printf("Will disable TimeMachine for rootfs.\n");
            CFPreferencesSetValue(CFSTR("rootfs_enabled"), kCFBooleanFalse, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        }
        if (number != nil) {
            CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), newInt([number intValue]), bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("Successfully set TimeMachine to backup up to most %s snapshots for rootfs.\n", [number UTF8String]);
            CFDictionaryRef settings = loadPrefs();
            if (settings == NULL) {
                settings = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
            }
            if (!CFDictionaryContainsKey(settings, CFSTR("rootfs_enabled")) || CFBooleanGetValue(CFDictionaryGetValue(settings, CFSTR("rootfs_enabled")))) {
                printf("Now delete the extra snapshot.\n");
                if (do_timemachine("/", false, [number intValue]) == 0) {
                    printf("Successfully delete the extra snapshot.\n");
                } else {
                    printf("There is nothing to do.\n");
                }
            } else {
                printf("TimeMachine for rootfs is disabled.\n");
            }
            CFRelease(settings);
        }
    } else if ([filePath isEqualToString:@"/private/var"]) {
        if ([args containsObject:@"--enable"]) {
            printf("Will enable TimeMachine for datafs.\n");
            CFPreferencesSetValue(CFSTR("datafs_enabled"), kCFBooleanTrue, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        } else if ([args containsObject:@"--disable"]) {
            printf("Will disable TimeMachine for datafs.\n");
            CFPreferencesSetValue(CFSTR("datafs_enabled"), kCFBooleanFalse, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        }
        if (number != nil) {
            CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), newInt([number intValue]), bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            printf("Successfully set TimeMachine to backup up to most %s snapshots for datafs.\n", [number UTF8String]);
            CFDictionaryRef settings = loadPrefs();
            if (settings == NULL) {
                settings = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
            }
            if (!CFDictionaryContainsKey(settings, CFSTR("datafs_enabled")) || CFBooleanGetValue(CFDictionaryGetValue(settings, CFSTR("datafs_enabled")))) {
                printf("Now delete the extra snapshot.\n");
                if (do_timemachine("/private/var", false, [number intValue]) == 0) {
                    printf("Successfully delete the extra snapshot.\n");
                } else {
                    printf("There is nothing to do.\n");
                }
            } else {
                printf("TimeMachine for datafs is disabled.\n");
            }
            CFRelease(settings);
        }
    } else {
        usage();
        return 1;
    }
    return 0;
}

int t(NSArray *args) {
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
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:@"/Library/LaunchDaemons/com.michael.TimeMachine.plist"];
    if (hour == nil) {
        hour = [NSString stringWithFormat:@"%@", settings[@"StartCalendarInterval"][@"Hour"]];
    } else if (minute == nil) {
        minute = [NSString stringWithFormat:@"%@", settings[@"StartCalendarInterval"][@"Minute"]];
    }
    printf("Will modify time to %s:%s.\n", [hour UTF8String], [minute UTF8String]);
    run_system("launchctl unload /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    NSString *plistFile = @"/Library/LaunchDaemons/com.michael.TimeMachine.plist";
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:plistFile];
    plist[@"StartCalendarInterval"][@"Hour"] = @([hour integerValue]);
    plist[@"StartCalendarInterval"][@"Minute"] = @([minute integerValue]);
    [[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil] writeToFile:plistFile atomically:YES];
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
            status = f(args);
            if (status != 0) {
                return status;
            }
        }
        if ([args containsObject:@"-t"]) {
            status = t(args);
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
