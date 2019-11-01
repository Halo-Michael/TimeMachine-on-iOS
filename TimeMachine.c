#include <fcntl.h>
#include <regex.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/snapshot.h>
#include <sys/uio.h>
#include <time.h>
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
    return (ret);
}

int do_timemachine(const char *vol)
{
    if (strcmp(vol, "/") != 0 && strcmp(vol, "/private/var") != 0 && strcmp(vol, "/var") != 0) {
        perror("what?");
        return 1;
    }
    
    int max_snapshot = 0;
    if (access("/var/mobile/Library/Preferences/com.michael.TimeMachine.plist",0)) {
        max_snapshot = 7;
    } else {
        int check;
        if (! access("/tmp/timemachine",0)) {
            remove("/tmp/timemachine");
        }
        if (strcmp(vol, "/") == 0) {
            run_cmd("plutil -key max_rootfs_snapshot /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine");
        } else {
            run_cmd("plutil -key max_datafs_snapshot /var/mobile/Library/Preferences/com.michael.TimeMachine.plist > /tmp/timemachine");
        }
        FILE *fp = fopen("/tmp/timemachine", "r");
        if ((check = fgetc(fp)) != EOF) {
            fclose(fp);
            fp = fopen("/tmp/timemachine", "r");
            fscanf(fp, "%d", &max_snapshot);
        } else {
            max_snapshot = 7;
        }
        fclose(fp);
        remove("/tmp/timemachine");
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
    
    if (access("/tmp/snapshots",0)) {
        FILE *fp = fopen("/tmp/snapshots","r+");
        fclose(fp);
    } else {
        remove("/tmp/snapshots");
        FILE *fp = fopen("/tmp/snapshots","r+");
        fclose(fp);
    }
    
    char *p = &abuf[0];
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
                FILE *fp = fopen("/tmp/snapshots","a+");
                fprintf(fp, "%s", name);
                fprintf(fp, "%s", "\n");
                fclose(fp);
            }
        }
        
        p += len;
    }
    
    int end, max_snapshot_num=0;
    if (!access("/tmp/snapshots",0)) {
        FILE *fp = fopen("/tmp/snapshots", "r");
        while ((end = fgetc(fp)) != EOF) {
            if (end == '\n') {
                max_snapshot_num++;
            }
        }
        fclose(fp);
    }
    
    if (max_snapshot_num > max_snapshot) {
        for (max_snapshot_num; max_snapshot_num > max_snapshot; max_snapshot_num--) {
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
                if (EOF == c) {
                    break;
                }
                if ('\n' == c) {
                    break;
                }
            }
            if (EOF != c)
                while (1) {
                    c = fgetc(fin);
                    if (EOF == c) {
                        break;
                    }
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


int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    run_cmd("/etc/rc.d/snapshotcheck");
    do_timemachine("/");
    do_timemachine("/private/var");
    printf("TimeMachine on iOS's work is down, enjoy safety.\n");
    return 0;
}
