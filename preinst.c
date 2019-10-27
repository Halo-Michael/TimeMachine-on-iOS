#include <fcntl.h>
#include <spawn.h>
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
    if (ret != 0){
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
    char c, version;
    run_cmd("sw_vers -productVersion > /tmp/snapshotcheck");
    FILE *fp = fopen("/tmp/snapshotcheck", "r");
    fscanf(fp, "%c%c", &c, &version);
    fclose(fp);
    remove("/tmp/snapshotcheck");
    if (version == '1' || version == '2'){
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
        int has_orig_fs = 0, has_electra_prejailbreak = 0;
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
                if (strcmp(name, "orig-fs") == 0){
                    has_orig_fs = 1;
                }
                if (strcmp(name, "electra-prejailbreak") == 0){
                    has_electra_prejailbreak = 1;
                }
            }
            
            p += len;
        }
        
        if (has_orig_fs == 1){
            printf("Will rename snapshot \"orig-fs\" on fs / to \"com.apple.TimeMachine.orig-fs\"\n");
            do_rename("/", "orig-fs", "com.apple.TimeMachine.orig-fs");
        }
        if (has_electra_prejailbreak == 1){
            printf("Will rename snapshot \"electra-prejailbreak\" on fs / to \"com.apple.TimeMachine.electra-prejailbreak\"\n");
            do_rename("/", "electra-prejailbreak", "com.apple.TimeMachine.electra-prejailbreak");
        }
    } else if (version == '0'){
        printf("iOS10 founded, skip orig snapshot check.\n");
    } else {
        printf("Wrong iOS version detected, now exit.\n");
        return 1;
    }
    if (! access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)){
        if (! access("/tmp/timemachine_upgrade",0)){
            remove("/tmp/timemachine_upgrade");
        }
        run_cmd("plutil -key setrootsnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine_upgrade");
        int check;
        FILE *fp = fopen("/tmp/timemachine_upgrade", "r");
        if ((check = fgetc(fp)) != EOF){
            run_cmd("plutil -key max_rootfs_snapshot -int `plutil -key setrootsnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist` /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            run_cmd("plutil -key setrootsnnum -remove /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        }
        fclose(fp);
        remove("/tmp/timemachine_upgrade");
        run_cmd("plutil -key setdatasnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine_upgrade");
        fp = fopen("/tmp/timemachine_upgrade", "r");
        if ((check = fgetc(fp)) != EOF){
            run_cmd("plutil -key max_datafs_snapshot -int `plutil -key setrootsnnum /var/mobile/Library/Preferences/com.michael.TimeMachine.plist` /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
            run_cmd("plutil -key setrootsnnum -remove /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        }
        fclose(fp);
        remove("/tmp/timemachine_upgrade");
    }
    return 0;
}
