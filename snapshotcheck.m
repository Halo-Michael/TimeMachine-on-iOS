#import <Foundation/Foundation.h>
#import <regex.h>
#import <removefile.h>
#import <sys/mount.h>
#import <sys/snapshot.h>
#import <sys/stat.h>
#import "utils.h"

int main() {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }

    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
        printf("iOS11 or higher version detected, now checking orig snapshot...\n");
        if (snapshot_check("/", "orig-fs")) {
            if (snapshot_check("/", "com.apple.TimeMachine.orig-fs")) {
                bool mnt2Existed = false;
                if ([[NSFileManager defaultManager] fileExistsAtPath:@"/mnt2" isDirectory:&mnt2Existed]) {
                    if (!mnt2Existed) {
                        removefile("/mnt2", NULL, REMOVEFILE_RECURSIVE);
                    }
                }
                if (!mnt2Existed) {
                    mkdir("/mnt2", 00755);
                }
                int dirfd = open("/", O_RDONLY, 0);
                if (dirfd < 0) {
                    perror("open");
                    return 3;
                }
                int count = fs_snapshot_mount(dirfd, "/mnt2", "orig-fs", 0);
                close(dirfd);
                if (count < 0) {
                    perror("fs_snapshot_mount");
                    return 4;
                }
                char *snapshot_name = NULL;
                FILE *fp = fopen("/.com.michael.TimeMachine", "r");
                if (fp == NULL) {
                    time_t time_T = time(NULL);
                    struct tm *tmTime = localtime(&time_T);
                    char* format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
                    snapshot_name = (char *)calloc(42, sizeof(char));
                    strftime(snapshot_name, sizeof(snapshot_name), format, tmTime);
                } else {
                    fseek(fp, 0, SEEK_END);
                    unsigned long strLen = ftell(fp) + 1;
                    fseek(fp, 0, SEEK_SET);
                    snapshot_name = (char *)calloc(strLen, sizeof(char));
                    fread(snapshot_name, sizeof(char), strLen, fp);
                    fclose(fp);
                    regex_t predicate;
                    regcomp(&predicate, "^(com.apple.TimeMachine.)[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}$", REG_EXTENDED | REG_NEWLINE | REG_NOSUB);
                    if (regexec(&predicate, snapshot_name, 0, NULL, 0) != 0) {
                        free(snapshot_name);
                        time_t time_T = time(NULL);
                        struct tm *tmTime = localtime(&time_T);
                        const char *format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
                        snapshot_name = (char *)calloc(42, sizeof(char));
                        strftime(snapshot_name, sizeof(snapshot_name), format, tmTime);
                    }
                    regfree(&predicate);
                }
                unmount("/mnt2", MNT_FORCE);
                if (!mnt2Existed) {
                    removefile("/mnt2", NULL, REMOVEFILE_RECURSIVE);
                }
                printf("Will rename snapshot \"orig-fs\" on fs / to \"%s\"\n", snapshot_name);
                snapshot_rename("/", "orig-fs", snapshot_name);
                free(snapshot_name);
                removefile("/.com.michael.TimeMachine", NULL, REMOVEFILE_RECURSIVE);
            } else {
                printf("Will rename snapshot \"orig-fs\" on fs / to \"com.apple.TimeMachine.orig-fs\"\n");
                snapshot_rename("/", "orig-fs", "com.apple.TimeMachine.orig-fs");
            }
        }
        if (snapshot_check("/", "electra-prejailbreak")) {
            printf("Will rename snapshot \"electra-prejailbreak\" on fs / to \"com.apple.TimeMachine.electra-prejailbreak\"\n");
            snapshot_rename("/", "electra-prejailbreak", "com.apple.TimeMachine.electra-prejailbreak");
        }
    } else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3) {
        printf("iOS10 detected, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 2;
    }
    return 0;
}
