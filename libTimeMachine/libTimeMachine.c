#include <CoreFoundation/CoreFoundation.h>
#include <sys/snapshot.h>
#include "libTimeMachine.h"

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
