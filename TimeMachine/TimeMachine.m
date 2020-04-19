#include <regex.h>
#include <sys/snapshot.h>

int do_create(const char *vol, const char *snap)
{
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }

    int ret = fs_snapshot_create(dirfd, snap, 0);
    if (ret != 0) {
        perror("fs_snapshot_create");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return (ret);
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
    return ret;
}

int do_timemachine(const char *vol)
{
    NSString *const settingsPlist = @"/var/mobile/Library/Preferences/com.michael.TimeMachine.plist";
    NSDictionary *const settings = [NSDictionary dictionaryWithContentsOfFile:settingsPlist];
    if (strcmp(vol, "/") != 0 && strcmp(vol, "/private/var") != 0 && strcmp(vol, "/var") != 0) {
        perror("what?");
        return 1;
    }

    int max_snapshot = 3;
    if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist", F_OK) == 0) {
        if (strcmp(vol, "/") == 0) {
            if (settings[@"max_rootfs_snapshot"]) {
                max_snapshot = [settings[@"max_rootfs_snapshot"] intValue];
            }
        }
        if (strcmp(vol, "/private/var") == 0 || strcmp(vol, "/var") == 0) {
            if (settings[@"max_datafs_snapshot"]) {
                max_snapshot = [settings[@"max_datafs_snapshot"] intValue];
            }
        }
    }

    if (max_snapshot != 0) {
        time_t time_T;
        time_T = time(NULL);
        struct tm *tmTime;
        tmTime = localtime(&time_T);
        char* format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
        char cre_snapshot[100];
        strftime(cre_snapshot, sizeof(cre_snapshot), format, tmTime);
        printf("Will create snapshot named \"%s\" on fs \"%s\"...\n", cre_snapshot, vol);
        do_create(vol, cre_snapshot);
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

int main()
{
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }

    int ststus = system("/etc/rc.d/snapshotcheck");
    if (WEXITSTATUS(status) != 0) {
        printf("Error in command: /etc/rc.d/snapshotcheck\n");
        return WEXITSTATUS(status);
    }

    do_timemachine("/");
    do_timemachine("/private/var");
    printf("TimeMachine on iOS's work is down, enjoy safety.\n");
    printf("\n");
    return 0;
}
