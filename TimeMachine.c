#include <CoreFoundation/CoreFoundation.h>
#include "utils.h"

int main() {
    if (getuid() != 0) {
        setuid(0);
    }

    if (getuid() != 0) {
        printf("Can't set uid as 0.\n");
        return 1;
    }

    run_system("/etc/rc.d/snapshotcheck");

    CFDictionaryRef settings = loadPrefs();
    if (settings == NULL) {
        settings = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
    }

    if (!CFDictionaryContainsKey(settings, CFSTR("rootfs_enabled")) || CFBooleanGetValue(CFDictionaryGetValue(settings, CFSTR("rootfs_enabled")))) {
        int max_snapshot = 3;
        if (CFDictionaryContainsKey(settings, CFSTR("max_rootfs_snapshot"))) {
            CFTypeRef num = CFDictionaryGetValue(settings, CFSTR("max_rootfs_snapshot"));
            if (CFGetTypeID(num) == CFNumberGetTypeID()) {
                CFNumberGetValue(num, kCFNumberIntType, &max_snapshot);
            } else {
                CFPreferencesSetValue(CFSTR("max_rootfs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            }
            CFRelease(num);
        }
        do_timemachine("/", true, max_snapshot);
    }
    if (!CFDictionaryContainsKey(settings, CFSTR("datafs_enabled")) || CFBooleanGetValue(CFDictionaryGetValue(settings, CFSTR("datafs_enabled")))) {
        int max_snapshot = 3;
        if (CFDictionaryContainsKey(settings, CFSTR("max_datafs_snapshot"))) {
            CFTypeRef num = CFDictionaryGetValue(settings, CFSTR("max_datafs_snapshot"));
            if (CFGetTypeID(num) == CFNumberGetTypeID()) {
                CFNumberGetValue(num, kCFNumberIntType, &max_snapshot);
            } else {
                CFPreferencesSetValue(CFSTR("max_datafs_snapshot"), NULL, bundleID, CFSTR("mobile"), kCFPreferencesAnyHost);
            }
            CFRelease(num);
        }
        do_timemachine("/private/var", true, max_snapshot);
    }
    CFRelease(settings);

    printf("TimeMachine on iOS's work is down, enjoy safety.\n\n");
    return 0;
}
