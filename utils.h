#include <CoreFoundation/CoreFoundation.h>
#include <sys/snapshot.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_10_3
#   define kCFCoreFoundationVersionNumber_iOS_10_3 1349.56
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#   define kCFCoreFoundationVersionNumber_iOS_11_0 1443.00
#endif

int do_create(const char *vol, const char *snap) {
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

int do_check(const char *num) {
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

int do_delete(const char *vol, const char *snap) {
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

int do_rename(const char *vol, const char *snap, const char *nw) {
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
    return ret;
}

void run_system(const char *cmd) {
    int status = system(cmd);
    if (WEXITSTATUS(status) != 0) {
        printf("Error in command: \"%s\"\n", cmd);
        exit(WEXITSTATUS(status));
    }
}
