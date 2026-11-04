#import "EHDiagnostics.h"
#import <mach/mach.h>
#import <mach/task_info.h>

@implementation EHDiagnostics

+ (NSDictionary<NSString *,NSString *> *)snapshot {
    task_vm_info_data_t vmInfo = {0};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
    NSString *memory = result == KERN_SUCCESS
        ? [NSByteCountFormatter stringFromByteCount:(long long)vmInfo.phys_footprint countStyle:NSByteCountFormatterCountStyleMemory]
        : @"Unavailable";

    NSString *uptime = [NSString stringWithFormat:@"%.0f sec", NSProcessInfo.processInfo.systemUptime];
    return @{
        @"App memory footprint": memory,
        @"System uptime": uptime,
        @"Bundle identifier": NSBundle.mainBundle.bundleIdentifier ?: @"Unknown"
    };
}

@end
