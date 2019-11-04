#include <fcntl.h>
#include <regex.h>
#include <spawn.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/snapshot.h>
#include <sys/uio.h>
#include <unistd.h>
extern char **environ;

int run_cmd(char *cmd)
{
    pid_t pid;
    char *argv[] = {"sh", "-c", cmd, NULL};
    int status = posix_spawn(&pid, "/bin/sh", NULL, NULL, argv, environ);
    if (status == 0) {
        if (waitpid(pid, &status, 0) == -1) {
            perror("waitpid");
        }
    }
    return status;
}

int do_rename(const char *vol, const char *snap, const char *nw)
{
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }
    
    int ret = fs_snapshot_rename(dirfd, snap, nw, 0);
    if (ret != 0) {
        perror("fs_snapshot_rename");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return (ret);
}

int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    char version[7];
    if (! access("/tmp/snapshotcheck",0)) {
        remove("/tmp/snapshotcheck");
    }
    run_cmd("sw_vers -productVersion > /tmp/snapshotcheck");
    FILE *fp = fopen("/tmp/snapshotcheck", "r");
    fscanf(fp, "%s", version);
    fclose(fp);
    remove("/tmp/snapshotcheck");
    int status_10, status_11, status_12, cflags = REG_EXTENDED;
    regmatch_t pmatch[1];
    const size_t nmatch = 1;
    regex_t reg;
    const char * pattern_10 = "^(10).+$";
    const char * pattern_11 = "^(11).+$";
    const char * pattern_12 = "^(12).+$";
    regcomp(&reg, pattern_10, cflags);
    status_10 = regexec(&reg, version, nmatch, pmatch, 0);
    regfree(&reg);
    regcomp(&reg, pattern_11, cflags);
    status_11 = regexec(&reg, version, nmatch, pmatch, 0);
    regfree(&reg);
    regcomp(&reg, pattern_12, cflags);
    status_12 = regexec(&reg, version, nmatch, pmatch, 0);
    regfree(&reg);
    if (status_11 == 0 || status_12 == 0) {
        printf("iOS11 or iOS12 founded, now checking orig snapshot...\n");
        int dirfd = open("/", O_RDONLY, 0);
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
        bool has_orig_fs = 0, has_electra_prejailbreak = 0;
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
                if (strcmp(name, "orig-fs") == 0) {
                    has_orig_fs = 1;
                }
                if (strcmp(name, "electra-prejailbreak") == 0) {
                    has_electra_prejailbreak = 1;
                }
            }
            
            p += len;
        }
        
        if (has_orig_fs == 1) {
            printf("Will rename snapshot \"orig-fs\" on fs / to \"com.apple.TimeMachine.orig-fs\"\n");
            do_rename("/", "orig-fs", "com.apple.TimeMachine.orig-fs");
        }
        if (has_electra_prejailbreak == 1) {
            printf("Will rename snapshot \"electra-prejailbreak\" on fs / to \"com.apple.TimeMachine.electra-prejailbreak\"\n");
            do_rename("/", "electra-prejailbreak", "com.apple.TimeMachine.electra-prejailbreak");
        }
    } else if (status_10 == 0) {
        printf("iOS10 founded, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 1;
    }
    if (! access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)) {
        if (! access("/tmp/timemachine_upgrade",0)) {
            remove("/tmp/timemachine_upgrade");
        }
        run_cmd("plutil -key setrootsnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine_upgrade");
        int check;
        FILE *fp = fopen("/tmp/timemachine_upgrade", "r");
        if ((check = fgetc(fp)) != EOF) {
            run_cmd("plutil -key max_rootfs_snapshot -int `plutil -key setrootsnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist` /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            run_cmd("plutil -key setrootsnnum -remove /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        }
        fclose(fp);
        remove("/tmp/timemachine_upgrade");
        run_cmd("plutil -key setdatasnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine_upgrade");
        fp = fopen("/tmp/timemachine_upgrade", "r");
        if ((check = fgetc(fp)) != EOF) {
            run_cmd("plutil -key max_datafs_snapshot -int `plutil -key setrootsnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist` /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            run_cmd("plutil -key setrootsnnum -remove /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        }
        fclose(fp);
        remove("/tmp/timemachine_upgrade");
    }
    return 0;
}
