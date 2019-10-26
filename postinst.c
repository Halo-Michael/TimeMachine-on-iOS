#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
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

int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    run_cmd("chown root:wheel /etc/rc.d/snapshotcheck");
    run_cmd("chmod 0755 /etc/rc.d/snapshotcheck");
    run_cmd("chown root:wheel /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    run_cmd("chown root:wheel /usr/libexec/TimeMachine");
    run_cmd("chmod 0755 /usr/libexec/TimeMachine");
    run_cmd("chown root:wheel /usr/bin/setTimeMachine");
    run_cmd("chmod 0755 /usr/bin/setTimeMachine");
    run_cmd("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    return 0;
}
