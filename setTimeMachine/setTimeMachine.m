#import <CoreFoundation/CoreFoundation.h>
#import <regex.h>
#import <sys/snapshot.h>
#import "../utils.h"

void usage() {
    printf("Usage:\tsetTimeMachine [OPTIONS...]\n");
    printf("\t-h\t\t\tPrint this help.\n");
    printf("\t-f <vol> -n <num>\tSet the max number of snapshots that need to be backed up for rootfs/datafs.\n");
    printf("\t-s\t\t\tShow current settings.\n");
}

void showSettings() {
    NSString *const settingsPlist = @"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist";
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:settingsPlist];
    bool isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist" isDirectory:&isDirectory]) {
        printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
        printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
    } else {
        if (isDirectory) {
            remove("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
            printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
        } else {
            int max_rootfs_snapshot = 3, max_datafs_snapshot = 3;
            if (settings[@"rootfs_enabled"] == nil || [settings[@"rootfs_enabled"] boolValue]) {
                printf("TimeMachine for rootfs is enabled.\n");
            } else {
                printf("TimeMachine for rootfs is disabled.\n");
            }
            if (settings [@"max_rootfs_snapshot"]) {
                max_rootfs_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
                if (max_rootfs_snapshot != 0) {
                    printf("Will save up to %d snapshots for rootfs\n", max_rootfs_snapshot);
                } else {
                    printf("Won't save snapshot for rootfs\n");
                }
            } else {
                printf("The max number of snapshots has not been set for rootfs (up to 3 snapshots will be saved by default)\n");
            }
            if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
                printf("TimeMachine for datafs is enabled.\n");
            } else {
                printf("TimeMachine for datafs is disabled.\n");
            }
            if (settings [@"max_datafs_snapshot"]) {
                max_datafs_snapshot = [settings[@"max_datafs_snapshot"] intValue];
                if (max_datafs_snapshot != 0) {
                    printf("Will save up to %d snapshots for datafs\n", max_datafs_snapshot);
                } else {
                    printf("Won't save snapshot for datafs\n");
                }
            } else {
                printf("The max number of snapshots has not been set for datafs (up to 3 snapshots will be saved by default)\n");
            }
        }
    }
}

int do_timemachine(const char *vol) {
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist"];
    if (strcmp(vol, "/") != 0 && strcmp(vol, "/private/var") != 0) {
        perror("what?");
        exit(1);
    }

    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    struct attrlist alist = { 0 };
    char abuf[2048];

    alist.commonattr = ATTR_BULK_REQUIRED;

    int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
    if (count < 0) {
        perror("fs_snapshot_list");
        exit(1);
    }

    char *p = &abuf[0];
    int max_snapshot = 0;
    bool isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist" isDirectory:&isDirectory]) {
        max_snapshot = 3;
    } else {
        if (isDirectory) {
            remove("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            max_snapshot = 3;
        } else {
            if (strcmp(vol, "/") == 0) {
                max_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
            }
            if (strcmp(vol, "/private/var") == 0) {
                max_snapshot = [settings[@"max_datafs_snapshot"] intValue];
            }
        }
    }

    NSMutableArray *snapshots = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        char *field = p;
        uint32_t len = *(uint32_t *)field;
        field += sizeof (uint32_t);
        attribute_set_t attrs = *(attribute_set_t *)field;
        field += sizeof (attribute_set_t);

        if (attrs.commonattr & ATTR_CMN_NAME) {
            attrreference_t ar = *(attrreference_t *)field;
            char *name = field + ar.attr_dataoffset;
            field += sizeof (attrreference_t);
            int status;
            int cflags = REG_EXTENDED;
            regmatch_t pmatch[1];
            const size_t nmatch = 1;
            regex_t reg;
            char *pattern = "^(com.apple.TimeMachine.)[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}$";
            regcomp(&reg, pattern, cflags);
            status = regexec(&reg, name, nmatch, pmatch, 0);
            regfree(&reg);
            if (status == 0) {
                [snapshots addObject:[NSString stringWithFormat:@"%s", name]];
            }
        }
        p += len;
    }

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

int main(int argc, char **argv) {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }

    int c;
    char *filesystem = NULL, *number = NULL;
    while ((c = getopt(argc, argv, "f:hn:s")) != -1) {
        switch (c) {
            case 'h':
                usage();
                return 0;
                break;
            case 's':
                showSettings();
                return 0;
                break;
            case 'f':
                filesystem = optarg;
                break;
            case 'n':
                if (!is_number(optarg)) {
                    usage();
                    return 1;
                } else {
                    number = optarg;
                }
                break;
        }
    }

    if (filesystem == NULL || number == NULL) {
        usage();
        return 1;
    }

    NSString *const settingsPlist = @"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist";

    bool isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist" isDirectory:&isDirectory]) {
        [[NSDictionary dictionary] writeToFile:settingsPlist atomically:NO];
    } else {
        if (isDirectory) {
            remove("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            [[NSDictionary dictionary] writeToFile:settingsPlist atomically:NO];
        }
    }

    NSString *filePath = [[NSString alloc] initWithUTF8String:filesystem];
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
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist"];
    if ([filePath isEqualToString:@"/"]) {
        modifyPlist(settingsPlist, ^(id plist) {
        plist[@"max_rootfs_snapshot"] = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%s", number] integerValue]]; });
        printf("Successfully set TimeMachine to backup up to most %s snapshots for rootfs.\n", number);
        if (settings[@"rootfs_enabled"] == nil || [settings[@"rootfs_enabled"] boolValue]) {
            printf("Now delete the extra snapshot.\n");
            if (do_timemachine("/") == 0) {
                printf("Successfully delete the extra snapshot.\n");
            } else {
                printf("There is nothing to do.\n");
            }
        } else {
            printf("TimeMachine for rootfs is disabled.\n");
        }
    } else if ([filePath isEqualToString:@"/private/var"]) {
        modifyPlist(settingsPlist, ^(id plist) {
        plist[@"max_datafs_snapshot"] = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%s", number] integerValue]]; });
        printf("Successfully set TimeMachine to backup up to most %s snapshots for datafs.\n", number);
        if (settings[@"datafs_enabled"] == nil || [settings[@"datafs_enabled"] boolValue]) {
            printf("Now delete the extra snapshot.\n");
            if (do_timemachine("/private/var") == 0) {
                printf("Successfully delete the extra snapshot.\n");
            } else {
                printf("There is nothing to do.\n");
            }
        } else {
            printf("TimeMachine for datafs is disabled.\n");
        }
    } else {
        usage();
        return 1;
    }

    run_system("killall -9 cfprefsd");
    printf("Now exit.\n");

    return 0;
}
