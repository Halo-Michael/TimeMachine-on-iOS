#ifdef __OBJC__

CFStringRef bundleID = CFSTR("com.michael.TimeMachine");

#endif

#include <sys/attr.h>
__attribute__((aligned(4)))
typedef struct val_attrs {
    uint32_t        length;
    attribute_set_t        returned;
    attrreference_t        name_info;
    char            name[MAXPATHLEN];
} val_attrs_t;
