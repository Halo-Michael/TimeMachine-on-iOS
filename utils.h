#ifndef _UTILS_H
#define _UTILS_H

#ifndef kCFCoreFoundationVersionNumber_iOS_10_3
#   define kCFCoreFoundationVersionNumber_iOS_10_3 1349.56
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#   define kCFCoreFoundationVersionNumber_iOS_11_0 1443.00
#endif

#ifdef __OBJC__

bool modifyPlist(NSString *filename, void (^function)(id));

#endif

int do_create(const char *vol, const char *snap);
int do_check(const char *num);
int do_delete(const char *vol, const char *snap);
int do_rename(const char *vol, const char *snap, const char *nw);
void run_system(const char *cmd);

#endif
