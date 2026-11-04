#import "EHDeviceInfo.h"
#import <sys/sysctl.h>

@implementation EHDeviceInfo

+ (NSString *)sysctlString:(const char *)name {
    size_t size = 0;
    if (sysctlbyname(name, NULL, &size, NULL, 0) != 0 || size == 0) {
        return @"Unknown";
    }
    char *buffer = calloc(1, size);
    if (!buffer) return @"Unknown";
    NSString *value = @"Unknown";
    if (sysctlbyname(name, buffer, &size, NULL, 0) == 0) {
        value = [NSString stringWithUTF8String:buffer] ?: @"Unknown";
    }
    free(buffer);
    return value;
}

+ (instancetype)currentInfo {
    EHDeviceInfo *info = [EHDeviceInfo new];
    info->_machineIdentifier = [self sysctlString:"hw.machine"];
    info->_buildVersion = [self sysctlString:"kern.osversion"];
    info->_osVersion = UIDevice.currentDevice.systemVersion ?: @"Unknown";
#if defined(__arm64e__)
    info->_architecture = @"arm64e";
#elif defined(__arm64__)
    info->_architecture = @"arm64";
#else
    info->_architecture = @"Unknown";
#endif
    info->_appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0.1.0";
    return info;
}

@end
