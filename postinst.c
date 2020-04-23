#include "utils.h"

int main() {
    if (getuid() != 0) {
        printf("Run this as root!\n");
        return 1;
    }

    run_system("chown root:wheel /etc/rc.d/snapshotcheck");
    run_system("chmod 6755 /etc/rc.d/snapshotcheck");
    run_system("chown root:wheel /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    run_system("chown root:wheel /usr/libexec/TimeMachine");
    run_system("chmod 6755 /usr/libexec/TimeMachine");
    run_system("chown root:wheel /usr/bin/setTimeMachine");
    run_system("chmod 6755 /usr/bin/setTimeMachine");
    run_system("launchctl load /Library/LaunchDaemons/com.michael.TimeMachine.plist");
    return 0;
}
