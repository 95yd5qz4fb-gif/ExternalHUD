#import "EHDiagnostics.h"
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <mach/task_info.h>
#import <sys/resource.h>
#import <unistd.h>

@implementation EHDiagnostics

+ (NSString *)cpuUsage {
    struct rusage usage = {0};
    if (getrusage(RUSAGE_SELF, &usage) != 0) return @"Unavailable";
    double user = (double)usage.ru_utime.tv_sec + (double)usage.ru_utime.tv_usec / 1000000.0;
    double system = (double)usage.ru_stime.tv_sec + (double)usage.ru_stime.tv_usec / 1000000.0;
    return [NSString stringWithFormat:@"%.2f sec user / %.2f sec system", user, system];
}

+ (NSDictionary<NSString *,NSString *> *)snapshot {
    task_vm_info_data_t vmInfo = {0};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vmInfo, &count);
    NSString *memory = result == KERN_SUCCESS
        ? [NSByteCountFormatter stringFromByteCount:(long long)vmInfo.phys_footprint countStyle:NSByteCountFormatterCountStyleMemory]
        : @"Unavailable";
    UIDevice *device = UIDevice.currentDevice;
    device.batteryMonitoringEnabled = YES;
    NSString *battery = device.batteryLevel >= 0
        ? [NSString stringWithFormat:@"%.0f%%", device.batteryLevel * 100.0]
        : @"Unavailable";
    NSString *thermal = @"Unknown";
    if (@available(iOS 11.0, *)) {
        switch (NSProcessInfo.processInfo.thermalState) {
            case NSProcessInfoThermalStateNominal: thermal = @"Nominal"; break;
            case NSProcessInfoThermalStateFair: thermal = @"Fair"; break;
            case NSProcessInfoThermalStateSerious: thermal = @"Serious"; break;
            case NSProcessInfoThermalStateCritical: thermal = @"Critical"; break;
            default: thermal = @"Unknown"; break;
        }
    }
    return @{
        @"App memory footprint": memory,
        @"App CPU": [self cpuUsage],
        @"Battery": battery,
        @"Thermal state": thermal,
        @"System uptime": [NSString stringWithFormat:@"%.0f sec", NSProcessInfo.processInfo.systemUptime],
        @"Process ID": [NSString stringWithFormat:@"%d", getpid()],
        @"Bundle identifier": NSBundle.mainBundle.bundleIdentifier ?: @"Unknown"
    };
}

@end
