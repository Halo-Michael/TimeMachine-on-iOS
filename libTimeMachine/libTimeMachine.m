#import <Foundation/Foundation.h>
#import <removefile.h>
#import <regex.h>
#import <sys/snapshot.h>
#import "libTimeMachine.h"

NSDictionary *loadPrefs() {
    CFArrayRef keyList = CFPreferencesCopyKeyList(bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
    if (keyList != NULL) {
        return (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost));
    }
    removefile("/private/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", NULL, REMOVEFILE_RECURSIVE);
    CFPreferencesSynchronize(bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
    return nil;
}

NSMutableArray *copy_snapshot_list(const char *vol) {
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
                NSString *snapshotName = [NSString stringWithFormat:@"%s", entry->name];
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^(com.apple.TimeMachine.)[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}$"];
                if ([predicate evaluateWithObject:snapshotName]) {
                    [snapshots addObject:snapshotName];
                }
            }
            entry = (val_attrs_t *)((char *)entry + entry->length);
        }
        bzero(&buf, sizeof(buf));
    }
    close(dirfd);

    if (retcount < 0) {
        perror("fs_snapshot_list");
        return nil;
    }

    return snapshots;
}

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

CFNumberRef newInt(int value) {
    return CFNumberCreate(NULL, kCFNumberIntType, &value);
}
