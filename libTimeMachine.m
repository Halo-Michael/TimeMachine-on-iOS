#import <Foundation/Foundation.h>
#import <regex.h>
#import <removefile.h>
#import <sys/snapshot.h>
#import "utils.h"

__attribute__((aligned(4)))
typedef struct val_attrs {
    uint32_t        length;
    attribute_set_t        returned;
    attrreference_t        name_info;
    char            name[MAXPATHLEN];
} val_attrs_t;

bool is_number(const char *num) {
    if (strcmp(num, "0") == 0) {
        return true;
    }
    const char* p = num;
    if (*p < '1' || *p > '9') {
        return false;
    } else {
        p++;
    }
    while (*p) {
        if(*p < '0' || *p > '9') {
            return false;
        } else {
            p++;
        }
    }
    return true;
}

int snapshot_create(const char *vol, const char *snap) {
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    int ret = fs_snapshot_create(dirfd, snap, 0);
    close(dirfd);
    if (ret != 0) {
        perror("fs_snapshot_create");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return ret;
}

bool snapshot_check(const char *vol, const char *snap) {
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    struct attrlist attr_list = { 0 };

    attr_list.commonattr = ATTR_BULK_REQUIRED;

    val_attrs_t buf;
    bzero(&buf, sizeof(buf));
    int retcount;
    while ((retcount = fs_snapshot_list(dirfd, &attr_list, &buf, sizeof(buf), 0))>0) {
        val_attrs_t *entry = &buf;
        for (int i = 0; i < retcount; i++) {
            if (entry->returned.commonattr & ATTR_CMN_NAME) {
                if (strcmp(entry->name, snap) == 0) {
                    close(dirfd);
                    return true;
                }
            }
            entry = (val_attrs_t *)((char *)entry + entry->length);
        }
        bzero(&buf, sizeof(buf));
    }
    close(dirfd);

    if (retcount < 0) {
        perror("fs_snapshot_list");
        exit(1);
    }

    return false;
}

int snapshot_delete(const char *vol, const char *snap) {
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    int ret = fs_snapshot_delete(dirfd, snap, 0);
    close(dirfd);
    if (ret != 0) {
        perror("fs_snapshot_delete");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return ret;
}

int snapshot_rename(const char *vol, const char *snap, const char *nw) {
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    int ret = fs_snapshot_rename(dirfd, snap, nw, 0);
    close(dirfd);
    if (ret != 0) {
        perror("fs_snapshot_rename");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return ret;
}

void run_system(const char *cmd) {
    int status = system(cmd);
    if (WEXITSTATUS(status) != 0) {
        perror(cmd);
        exit(WEXITSTATUS(status));
    }
}

CFDictionaryRef loadPrefs() {
    CFArrayRef keyList = CFPreferencesCopyKeyList(bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
    if (keyList != NULL) {
        CFDictionaryRef prefs = CFPreferencesCopyMultiple(keyList, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        CFRelease(keyList);
        return prefs;
    } else {
        removefile("/private/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", NULL, REMOVEFILE_RECURSIVE);
        CFPreferencesSynchronize(bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
        return NULL;
    }
}

bool modifyPlist(NSString *filename, void (^function)(id)) {
    NSData *data = [NSData dataWithContentsOfFile:filename];
    if (data == nil) {
        return false;
    }
    NSPropertyListFormat format = 0;
    id plist = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:nil];
    if (plist == nil) {
        return false;
    }
    if (function) {
        function(plist);
    }
    NSData *newData = [NSPropertyListSerialization dataWithPropertyList:plist format:format options:0 error:nil];
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

CFNumberRef newInt(const int value) {
    return CFAutorelease(CFNumberCreate(NULL, kCFNumberIntType, &value));
}

int do_timemachine(const char *vol, const bool create, const int max_snapshot) {
    if (create && max_snapshot != 0) {
        time_t time_T = time(NULL);
        struct tm *tmTime = localtime(&time_T);
        const char *format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
        char *cre_snapshot = (char *)calloc(42, sizeof(char));
        strftime(cre_snapshot, 42, format, tmTime);
        printf("Will create snapshot named \"%s\" on fs \"%s\"...\n", cre_snapshot, vol);
        if (strcmp(vol, "/") == 0) {
            removefile("/.com.michael.TimeMachine", NULL, REMOVEFILE_RECURSIVE);
            FILE *fp = fopen("/.com.michael.TimeMachine", "w");
            fprintf(fp, "%s", cre_snapshot);
            fclose(fp);
            snapshot_create(vol, cre_snapshot);
            removefile("/.com.michael.TimeMachine", NULL, REMOVEFILE_RECURSIVE);
        } else {
            snapshot_create(vol, cre_snapshot);
        }
        free(cre_snapshot);
    }

    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    struct attrlist attr_list = { 0 };

    attr_list.commonattr = ATTR_BULK_REQUIRED;

    val_attrs_t buf;
    bzero(&buf, sizeof(buf));
    NSMutableArray *snapshots = [NSMutableArray array];
    int retcount;
    while ((retcount = fs_snapshot_list(dirfd, &attr_list, &buf, sizeof(buf), 0))>0) {
        val_attrs_t *entry = &buf;
        for (int i = 0; i < retcount; i++) {
            if (entry->returned.commonattr & ATTR_CMN_NAME) {
                regex_t predicate;
                regcomp(&predicate, "^(com.apple.TimeMachine.)[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}$", REG_EXTENDED | REG_NEWLINE | REG_NOSUB);
                if (regexec(&predicate, entry->name, 0, NULL, 0) == 0) {
                    [snapshots addObject:[NSString stringWithFormat:@"%s", entry->name]];
                }
                regfree(&predicate);
            }
            entry = (val_attrs_t *)((char *)entry + entry->length);
        }
        bzero(&buf, sizeof(buf));
    }
    close(dirfd);

    if (retcount < 0) {
        perror("fs_snapshot_list");
        exit(1);
    }

    int ret = 1;
    while ([snapshots count] > max_snapshot) {
        printf("Will delete snapshot named \"%s\" on fs \"%s\"...\n", [[snapshots objectAtIndex:0] UTF8String], vol);
        snapshot_delete(vol, [[snapshots objectAtIndex:0] UTF8String]);
        [snapshots removeObjectAtIndex:0];
        ret = 0;
    }
    return ret;
}
