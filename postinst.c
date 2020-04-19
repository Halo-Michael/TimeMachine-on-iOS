#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main()
{
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    char *commands[8] = {"chown root:wheel /etc/rc.d/snapshotcheck", "chmod 6755 /etc/rc.d/snapshotcheck", "chown root:wheel /Library/LaunchDaemons/com.michael.TimeMachine.plist", "chown root:wheel /usr/libexec/TimeMachine", "chmod 6755 /usr/libexec/TimeMachine", "chown root:wheel /usr/bin/setTimeMachine", "chmod 6755 /usr/bin/setTimeMachine", "launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist"
    };

    int status = 0, i = 0;
    while (i < 8) {
        status = system(commands[i]);
        if (WEXITSTATUS(status) == 0) {
            i++;
        } else {
            printf("Error in command: %s\n", commands[i]);
            return WEXITSTATUS(status);
        }
    }
    return 0;
}
