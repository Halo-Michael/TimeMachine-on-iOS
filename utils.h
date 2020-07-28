#ifndef _UTILS_H
#define _UTILS_H

#ifndef kCFCoreFoundationVersionNumber_iOS_10_3
#   define kCFCoreFoundationVersionNumber_iOS_10_3 1349.56
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#   define kCFCoreFoundationVersionNumber_iOS_11_0 1443.00
#endif

#ifdef __OBJC__

#import "libTimeMachine/libTimeMachine.h"

NSDictionary *loadPrefs();
bool modifyPlist(NSString *filename, void (^function)(id));
CFNumberRef newInt(int value);

#endif

bool is_number(const char *num);
int snapshot_create(const char *vol, const char *snap);
bool snapshot_check(const char *vol, const char *snap);
int snapshot_delete(const char *vol, const char *snap);
int snapshot_rename(const char *vol, const char *snap, const char *nw);
void run_system(const char *cmd);

#endif
