#include <CoreFoundation/CoreFoundation.h>
#include <sys/snapshot.h>
#include "utils.h"

int main() {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
        printf("iOS11 or higher version detected, now checking orig snapshot...\n");
        int dirfd = open("/", O_RDONLY, 0);
        if (dirfd < 0) {
            perror("open");
            return 1;
        }

        struct attrlist alist = { 0 };
        char abuf[2048];

        alist.commonattr = ATTR_BULK_REQUIRED;

        int count = fs_snapshot_list(dirfd, &alist, &abuf[0], sizeof (abuf), 0);
        if (count < 0) {
            perror("fs_snapshot_list");
            return 1;
        }

        char *p = &abuf[0];
        bool has_orig_fs = false, has_electra_prejailbreak = false;
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
                    has_orig_fs = true;
                }
                if (strcmp(name, "electra-prejailbreak") == 0) {
                    has_electra_prejailbreak = true;
                }
            }
            p += len;
        }

        if (has_orig_fs == true) {
            printf("Will rename snapshot \"orig-fs\" on fs / to \"com.apple.TimeMachine.orig-fs\"\n");
            do_rename("/", "orig-fs", "com.apple.TimeMachine.orig-fs");
        }
        if (has_electra_prejailbreak == true) {
            printf("Will rename snapshot \"electra-prejailbreak\" on fs / to \"com.apple.TimeMachine.electra-prejailbreak\"\n");
            do_rename("/", "electra-prejailbreak", "com.apple.TimeMachine.electra-prejailbreak");
        }
    } else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3) {
        printf("iOS10 detected, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 1;
    }
    return 0;
}
