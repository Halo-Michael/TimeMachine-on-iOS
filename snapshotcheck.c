#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include <sys/snapshot.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_10_3
#   define kCFCoreFoundationVersionNumber_iOS_10_3 1349.56
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#   define kCFCoreFoundationVersionNumber_iOS_11_0 1443.00
#endif

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

int read_cmd(char* cmd, char* result)
{
    char buffer[10240];
    FILE* pipe = popen(cmd, "r");
    if (!pipe) {
        return -1;
    }
    while (!feof(pipe)) {
        if (fgets(buffer, 4096, pipe)) {
            strcat(result, buffer);
        }
    }
    pclose(pipe);
    return 0;
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
    
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
        printf("iOS11 or higher version detected, now checking orig snapshot...\n");
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
    } else if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_3) {
        printf("iOS10 detected, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 1;
    }
    return 0;
}
