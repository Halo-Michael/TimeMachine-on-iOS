#include <regex.h>
#include <sys/snapshot.h>

bool modifyPlist(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = 0;
    NSError *error = nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:&error];
    if (newData == nil) {
        return false;
    }
    if (![data isEqual:newData]) {
        if (![newData writeToFile:filename atomically:YES]) {
            return false;
        }
    }
    return true;
}

void usage()
{
    printf("Usage:\tsetTimeMachine [OPTIONS...]\n");
    printf("\t-h\t\t\tPrint this help.\n");
    printf("\t-f <vol> -n <num>\tSet the max number of snapshots that need to be backed up for rootfs/datafs.\n");
    printf("\t-s\t\t\tShow current settings.\n");
    exit(2);
}

int do_delete(const char *vol, const char *snap)
{
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }
    
    int ret = fs_snapshot_delete(dirfd, snap, 0);
    if (ret != 0) {
        perror("fs_snapshot_delete");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return (ret);
}

int do_check(const char *num)
{
    if (strcmp(num, "0") == 0) {
        return 0;
    }
    const char* p = num;
    if (*p < '1' || *p > '9') {
        return 1;
    } else {
        p++;
    }
    while (*p) {
        if(*p < '0' || *p > '9') {
            return 1;
        } else {
            p++;
        }
    }
    return 0;
}

int do_timemachine(const char *vol)
{
    NSString *const settingsPlist = @"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist";
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:settingsPlist];
    if (strcmp(vol, "/") != 0 && strcmp(vol, "/private/var") != 0 && strcmp(vol, "/var") != 0) {
        perror("what?");
        return 1;
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
    if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", F_OK) != 0) {
        max_snapshot = 7;
    } else {
        if (strcmp(vol, "/") == 0) {
            max_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
        }
        if (strcmp(vol, "/private/var") == 0 || strcmp(vol, "/var") == 0) {
            max_snapshot = [settings[@"max_datafs_snapshot"] intValue];
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
            do_delete(vol, [[snapshots objectAtIndex:0] UTF8String]);
            [snapshots removeObjectAtIndex:0];
        }
    }
    return 0;
}

int main(int argc, char **argv)
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    if (argc != 2) {
        if (argc != 5 || strcmp(argv[1], "-f") != 0 || strcmp(argv[3], "-n") != 0 || do_check(argv[4]) != 0) {
            usage();
        }
    } else if (strcmp(argv[1], "-s") != 0) {
        usage();
    }
    NSString *const settingsPlist = @"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist";
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:settingsPlist];
    if (strcmp(argv[1], "-s") == 0) {
        int max_rootfs_snapshot_printed = 0, max_datafs_snapshot_printed = 0;
        if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", F_OK) != 0) {
            printf("The max number of snapshots has not been set for rootfs (up to 7 snapshots will be saved by default)\n");
            max_rootfs_snapshot_printed = 1;
            printf("The max number of snapshots has not been set for datafs (up to 7 snapshots will be saved by default)\n");
            max_datafs_snapshot_printed = 1;
        } else {
            int max_rootfs_snapshot = 0, max_datafs_snapshot = 0;
            if (![[settings objectForKey:@"max_rootfs_snapshot"] isEqual:[NSNull null]]) {
                max_rootfs_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
            } else {
                printf("The max number of snapshots has not been set for rootfs (up to 7 snapshots will be saved by default)\n");
                max_rootfs_snapshot_printed = 1;
            }
            if (max_rootfs_snapshot != 0) {
                printf("Will save up to %d snapshots for rootfs\n", max_rootfs_snapshot);
                max_rootfs_snapshot_printed = 1;
            } else {
                if (max_rootfs_snapshot_printed == 0) {
                    printf("Won't save snapshot for rootfs\n");
                    max_rootfs_snapshot_printed = 1;
                }
            }
            if (![[settings objectForKey:@"max_datafs_snapshot"] isEqual:[NSNull null]]) {
                max_datafs_snapshot = [settings[@"max_datafs_snapshot"] intValue];
            } else {
                printf("The max number of snapshots has not been set for datafs (up to 7 snapshots will be saved by default)\n");
                max_datafs_snapshot_printed = 1;
            }
            if (max_datafs_snapshot != 0) {
                printf("Will save up to %d snapshots for datafs\n", max_datafs_snapshot);
                max_datafs_snapshot_printed = 1;
            } else {
                if (max_datafs_snapshot_printed == 0) {
                    printf("Won't save snapshot for datafs\n");
                    max_datafs_snapshot_printed = 1;
                }
            }
        }
        return 0;
    }
    if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", F_OK) != 0) {
        FILE *fp = fopen("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist","a+");
        fprintf(fp, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        fprintf(fp, "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
        fprintf(fp, "<plist version=\"1.0\">\n");
        fprintf(fp, "<dict>\n");
        fprintf(fp, "</dict>\n");
        fprintf(fp, "</plist>\n");
        fclose(fp);
    }
    if (strcmp(argv[2], "/") == 0) {
        modifyPlist(settingsPlist, ^(id plist) {
        plist[@"max_rootfs_snapshot"] = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%s", argv[4]] integerValue]]; });
        printf("Successfully set TimeMachine to backup up to most %s snapshots for rootfs, now delete the extra snapshot.\n", argv[4]);
        do_timemachine("/");
        printf("Successfully delete the extra snapshot.\n");
        printf("Now exit.\n");
    } else if (strcmp(argv[2], "/var") == 0 || strcmp(argv[2], "/var/") == 0 || strcmp(argv[2], "/private/var") == 0 || strcmp(argv[2], "/private/var/") == 0) {
        modifyPlist(settingsPlist, ^(id plist) {
        plist[@"max_datafs_snapshot"] = [NSNumber numberWithInteger:[[NSString stringWithFormat:@"%s", argv[4]] integerValue]]; });
        printf("Successfully set TimeMachine to backup up to most %s snapshots for varfs, now delete the extra snapshot.\n", argv[4]);
        do_timemachine("/private/var");
        printf("Successfully delete the extra snapshot.\n");
        printf("Now exit.\n");
    } else {
        usage();
    }
    return 0;
}
