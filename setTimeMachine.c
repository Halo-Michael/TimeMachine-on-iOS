#include <fcntl.h>
#include <regex.h>
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

void usage()
{
    printf("Usage:\tsetTimeMachine [OPTIONS...]\n");
    printf("\t-f <vol> -n <num>\tSet the max number of snapshots that need to be backed up for rootfs/datafs.\n");
    printf("\t-s\t\t\tShow current settings.\n");
    exit(2);
}

int do_delete(const char *vol, const char *snap)
{
    int dirfd = open(vol, O_RDONLY, 0);
    if (dirfd < 0) {
        perror("open");
        exit(1);
    }
    
    int ret = fs_snapshot_delete(dirfd, snap, 0);
    if (ret != 0){
        perror("fs_snapshot_delete");
        printf("Failure\n");
    } else {
        printf("Success\n");
    }
    return (ret);
}

int do_check(const char *num)
{
    if (strcmp(num, "0") == 0){
        return 0;
    }
    char* p = num;
    if (*p < '1' || *p > '9'){
        return 1;
    } else {
        p++;
    }
    while (*p){
        if(*p < '0' || *p > '9'){
            return 1;
        } else {
            p++;
        }
    }
    return 0;
}

int do_timemachine(const char *vol)
{
    if (strcmp(vol, "/") != 0 && strcmp(vol, "/private/var") != 0 && strcmp(vol, "/var") != 0){
        perror("what?");
        return 1;
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
    int max_snapshot = 0;
    if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)){
        max_snapshot = 7;
    } else {
        if (! access("/tmp/timemachine",0)){
            remove("/tmp/timemachine");
        }
        if (strcmp(vol, "/") == 0){
            run_cmd("plutil -key max_rootfs_snapshot /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine");
        } else {
            run_cmd("plutil -key max_datafs_snapshot /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine");
        }
        FILE *fp = fopen("/tmp/timemachine", "r");
        fscanf(fp, "%d", &max_snapshot);
        fclose(fp);
        remove("/tmp/timemachine");
    }
    if (access("/tmp/snapshots",0)){
        FILE *fp = fopen("/tmp/snapshots","r+");
        fclose(fp);
    } else {
        remove("/tmp/snapshots");
        FILE *fp = fopen("/tmp/snapshots","r+");
        fclose(fp);
    }
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
            char *pattern = "^(com.apple.TimeMachine).+$";
            regcomp(&reg, pattern, cflags);
            status = regexec(&reg, name, nmatch, pmatch, 0);
            if (status == 0 && strcmp(name, "com.apple.TimeMachine.orig-fs") != 0 && strcmp(name, "com.apple.TimeMachine.electra-prejailbreak") != 0){
                FILE *fp = fopen("/tmp/snapshots","a+");
                fprintf(fp, "%s", name);
                fprintf(fp, "%s", "\n");
                fclose(fp);
            }
        }
        
        p += len;
    }
    
    int end, max_snapshot_num=0;
    if (!access("/tmp/snapshots",0)){
        FILE *fp = fopen("/tmp/snapshots", "r");
        while((end = fgetc(fp)) != EOF)
        {
            if(end == '\n') max_snapshot_num++;
        }
        fclose(fp);
    }
    
    if (max_snapshot_num > max_snapshot){
        for (max_snapshot_num; max_snapshot_num > max_snapshot; max_snapshot_num--){
            char del_snapshot[41];
            FILE *fp = fopen("/tmp/snapshots", "r");
            fscanf(fp, "%s\n", &del_snapshot);
            fclose(fp);
            printf("Will delete snapshot named \"%s\" on fs \"%s\"...\n", del_snapshot, vol);
            do_delete(vol, del_snapshot);
            
            FILE *fin = fopen("/tmp/snapshots", "r"), *fout = fopen("/tmp/snapshots.tmp", "w");
            int c;
            while (1) {
                c = fgetc(fin);
                if (EOF == c) break;
                if ('\n' == c) break;
            }
            if (EOF != c )
                while (1) {
                    c = fgetc(fin);
                    if (EOF == c) break;
                    fputc(c,fout);
                }
            fclose(fin);
            fclose(fout);
            remove("/tmp/snapshots");
            rename("/tmp/snapshots.tmp", "/tmp/snapshots");
        }
    }
    remove("/tmp/snapshots");
}

int main(int argc, char **argv)
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    if (argc != 2){
        if (argc != 5 || strcmp(argv[1], "-f") != 0 || strcmp(argv[3], "-n") != 0 || do_check(argv[4]) != 0){
            usage();
        }
    } else if (strcmp(argv[1], "-s") != 0){
        usage();
    }
    if (strcmp(argv[1], "-s") == 0){
        int max_rootfs_snapshot_printed = 0, max_datafs_snapshot_printed = 0;
        if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)){
            printf("The max number of snapshots has not been set for rootfs (up to 7 snapshots will be saved by default)\n");
            max_rootfs_snapshot_printed = 1;
            printf("The max number of snapshots has not been set for datafs (up to 7 snapshots will be saved by default)\n");
            max_datafs_snapshot_printed = 1;
        } else {
            int check, max_rootfs_snapshot = 0, max_datafs_snapshot = 0;
            if (! access("/tmp/rootfs_max_num",0)){
                remove("/tmp/rootfs_max_num");
            }
            run_cmd("plutil -key max_rootfs_snapshot /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/rootfs_max_num");
            FILE *fp = fopen("/tmp/rootfs_max_num", "r");
            if ((check = fgetc(fp)) != EOF){
                fclose(fp);
                fp = fopen("/tmp/rootfs_max_num", "r");
                fscanf(fp, "%d", &max_rootfs_snapshot);
            } else {
                printf("The max number of snapshots has not been set for rootfs (up to 7 snapshots will be saved by default)\n");
                max_rootfs_snapshot_printed = 1;
            }
            fclose(fp);
            remove("/tmp/rootfs_max_num");
            if (max_rootfs_snapshot != 0){
                printf("Will save up to %d snapshots for rootfs\n", max_rootfs_snapshot);
                max_rootfs_snapshot_printed = 1;
            } else {
                if (max_rootfs_snapshot_printed == 0){
                    printf("Won't save snapshot for rootfs\n");
                    max_rootfs_snapshot_printed = 1;
                }
            }
            if (! access("/tmp/datafs_max_num",0)){
                remove("/tmp/datafs_max_num");
            }
            run_cmd("plutil -key max_datafs_snapshot /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/datafs_max_num");
            fp = fopen("/tmp/datafs_max_num", "r");
            if ((check = fgetc(fp)) != EOF){
                fclose(fp);
                fp = fopen("/tmp/datafs_max_num", "r");
                fscanf(fp, "%d", &max_datafs_snapshot);
            } else {
                printf("The max number of snapshots has not been set for datafs (up to 7 snapshots will be saved by default)\n");
                max_datafs_snapshot_printed = 1;
            }
            fclose(fp);
            remove("/tmp/datafs_max_num");
            if (max_datafs_snapshot != 0){
                printf("Will save up to %d snapshots for datafs\n", max_datafs_snapshot);
                max_datafs_snapshot_printed = 1;
            } else {
                if (max_datafs_snapshot_printed == 0){
                    printf("Won't save snapshot for datafs\n");
                    max_datafs_snapshot_printed = 1;
                }
            }
        }
        return 0;
    }
    char set[200];
    if (strcmp(argv[2], "/") == 0){
        if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)){
            run_cmd("plutil -create /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        }
        sprintf(set, "plutil -key max_rootfs_snapshot -int %s /var/mobile/Library/Preferences/com.michael.TimeMachine.plist", argv[4]);
        run_cmd(set);
        printf("Successfully set TimeMachine to backup up to most %s snapshots for rootfs, now delete the extra snapshot.\n", argv[4]);
        do_timemachine("/");
        printf("Successfully delete the extra snapshot.\n");
        printf("Now exit.\n");
    } else if (strcmp(argv[2], "/var") == 0 || strcmp(argv[2], "/var/") == 0 || strcmp(argv[2], "/private/var") == 0 || strcmp(argv[2], "/private/var/") == 0){
        if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)){
            run_cmd("plutil -create /var/mobile/Library/Preferences/com.michael.TimeMachine.plist");
        }
        sprintf(set, "plutil -key max_datafs_snapshot -int %s /var/mobile/Library/Preferences/com.michael.TimeMachine.plist", argv[4]);
        run_cmd(set);
        printf("Successfully set TimeMachine to backup up to most %s snapshots for varfs, now delete the extra snapshot.\n", argv[4]);
        do_timemachine("/private/var");
        printf("Successfully delete the extra snapshot.\n");
        printf("Now exit.\n");
    } else {
        usage();
    }
    return 0;
}
