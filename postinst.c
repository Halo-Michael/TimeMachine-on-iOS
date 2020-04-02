#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main()
{
    if (geteuid() != 0) {
        printf("Run this as root!\n");
        exit(1);
    }
    system("chown root:wheel /etc/rc.d/snapshotcheck");
    system("chmod 0755 /etc/rc.d/snapshotcheck");
    system("chown root:wheel /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    system("chown root:wheel /usr/libexec/TimeMachine");
    system("chmod 0755 /usr/libexec/TimeMachine");
    system("chown root:wheel /usr/bin/setTimeMachine");
    system("chmod 0755 /usr/bin/setTimeMachine");
    system("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    return 0;
}
