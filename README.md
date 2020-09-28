Now you can use "setTimeMachine" on Terminal to select the maximum number of snapshots you want to backup for TimeMachine!
Usage:	setTimeMachine [OPTIONS...]
  -h    Print this help.
  -f <vol> [--enable | --disable] [--n <number>]
        Set a way to backup snapshots for specify filesystem.
  -s    Show current settings.
  -t [--h <hour>] [--m <minute>]
        Set a time to backup snapshots(24-hour system).

Now you can use Snapback to restore a snapshot of the root/var fs
You can get Snapback on midnightchips’s repo https://repo.midnightchips.me

TimeMachine on iOS will creat snapshots at 2:00AM everyday to backup your system;
Will create rootfs and datafs snapshots by default;

To Build TimeMachine:
cd to the folder; then use "make all" command to build it.
