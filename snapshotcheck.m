#import <Foundation/Foundation.h>
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
                NSString *name = nil;
                FILE *fp = fopen("/.com.michael.TimeMachine", "r");
                if (fp == NULL) {
                    time_t time_T = time(NULL);
                    struct tm *tmTime = localtime(&time_T);
                    char* format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
                    char snapshot_name[42];
                    strftime(snapshot_name, sizeof(snapshot_name), format, tmTime);
                    name = [NSString stringWithFormat:@"%s", snapshot_name];
                } else {
                    NSMutableString *getString = [[NSMutableString alloc] init];
                    char buffer = fgetc(fp);
                    while (!feof(fp)) {
                        [getString appendFormat:@"%c", buffer];
                        buffer = fgetc(fp);
                    }
                    fclose(fp);
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^(com.apple.TimeMachine.)[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}$"];
                    if ([predicate evaluateWithObject:getString]) {
                        name = [NSString stringWithString:getString];
                    } else {
                        time_t time_T = time(NULL);
                        struct tm *tmTime = localtime(&time_T);
                        const char *format = "com.apple.TimeMachine.%Y-%m-%d-%H:%M:%S";
                        char snapshot_name[42];
                        strftime(snapshot_name, sizeof(snapshot_name), format, tmTime);
                        name = [NSString stringWithFormat:@"%s", snapshot_name];
                    }
                }
                unmount("/mnt2", MNT_FORCE);
                if (!mnt2Existed) {
                    removefile("/mnt2", NULL, REMOVEFILE_RECURSIVE);
                }
                printf("Will rename snapshot \"orig-fs\" on fs / to \"%s\"\n", [name UTF8String]);
                snapshot_rename("/", "orig-fs", [name UTF8String]);
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
