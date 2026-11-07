#import "EHProcessManager.h"
#import <mach/mach.h>
#import <signal.h>
#import <sys/proc.h>
#import <sys/sysctl.h>
#import <sys/types.h>
#import <unistd.h>

@interface EHProcessTarget ()
@property(nonatomic,assign,readwrite) pid_t processIdentifier;
@property(nonatomic,copy,readwrite) NSString *processName;
@property(nonatomic,copy,readwrite) NSString *bundleIdentifier;
@property(nonatomic,copy,readwrite) NSString *executablePath;
@property(nonatomic,assign,readwrite,getter=isCurrentProcess) BOOL currentProcess;
@end
@implementation EHProcessTarget @end

@interface EHProcessSession ()
@property(nonatomic,strong,readwrite) EHProcessTarget *target;
@property(nonatomic,assign,readwrite) EHProcessSessionStatus status;
@property(nonatomic,copy,readwrite) NSString *detail;
@property(nonatomic,assign,readwrite) mach_port_t taskPort;
@end
@implementation EHProcessSession
- (void)dealloc {
    if (_taskPort != MACH_PORT_NULL) mach_port_deallocate(mach_task_self(), _taskPort);
}
@end

@implementation EHProcessManager
+ (EHProcessTarget *)makeTarget:(pid_t)pid name:(NSString *)name {
    EHProcessTarget *target = [EHProcessTarget new];
    target.processIdentifier = pid;
    target.processName = name.length ? name : [NSString stringWithFormat:@"pid-%d", pid];
    target.executablePath = @"";
    target.bundleIdentifier = @"—";
    target.currentProcess = (pid == getpid());
    return target;
}

+ (EHProcessTarget *)currentProcess {
    return [self makeTarget:getpid() name:NSProcessInfo.processInfo.processName];
}

+ (NSArray<EHProcessTarget *> *)allProcesses {
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
    size_t length = 0;
    if (sysctl(mib, 4, NULL, &length, NULL, 0) != 0 || length == 0) return @[];

    struct kinfo_proc *entries = calloc(1, length);
    if (!entries) return @[];
    if (sysctl(mib, 4, entries, &length, NULL, 0) != 0) {
        free(entries);
        return @[];
    }

    NSMutableArray<EHProcessTarget *> *targets = [NSMutableArray array];
    size_t count = length / sizeof(struct kinfo_proc);
    for (size_t i = 0; i < count; i++) {
        pid_t pid = entries[i].kp_proc.p_pid;
        if (pid <= 0) continue;
        const char *rawName = entries[i].kp_proc.p_comm;
        NSString *name = rawName ? [NSString stringWithUTF8String:rawName] : nil;
        [targets addObject:[self makeTarget:pid name:name]];
    }
    free(entries);
    [targets sortUsingComparator:^NSComparisonResult(EHProcessTarget *a, EHProcessTarget *b) {
        return [a.processName localizedCaseInsensitiveCompare:b.processName];
    }];
    return targets;
}

+ (EHProcessTarget *)targetForPID:(pid_t)pid {
    for (EHProcessTarget *target in [self allProcesses]) {
        if (target.processIdentifier == pid) return target;
    }
    return nil;
}

+ (EHProcessSession *)attachToTarget:(EHProcessTarget *)target {
    EHProcessSession *session = [EHProcessSession new];
    session.target = target;
    session.taskPort = MACH_PORT_NULL;
    if (!target || target.processIdentifier <= 0) {
        session.status = EHProcessSessionStatusRejected;
        session.detail = @"Invalid PID.";
        return session;
    }
    if (kill(target.processIdentifier, 0) != 0) {
        session.status = EHProcessSessionStatusProcessExited;
        session.detail = @"Process exited or is not visible.";
        return session;
    }
    if (target.processIdentifier == getpid()) {
        session.taskPort = mach_task_self();
        mach_port_mod_refs(mach_task_self(), session.taskPort, MACH_PORT_RIGHT_SEND, 1);
        session.status = EHProcessSessionStatusAttachedToSelf;
        session.detail = @"Connected to own task port.";
        return session;
    }
    mach_port_t port = MACH_PORT_NULL;
    kern_return_t result = task_for_pid(mach_task_self(), target.processIdentifier, &port);
    if (result == KERN_SUCCESS && port != MACH_PORT_NULL) {
        session.taskPort = port;
        session.status = EHProcessSessionStatusAttached;
        session.detail = @"Mach task port acquired. No memory operations are performed.";
    } else {
        session.status = (result == KERN_FAILURE || result == KERN_INVALID_ARGUMENT)
            ? EHProcessSessionStatusPermissionDenied : EHProcessSessionStatusRejected;
        session.detail = [NSString stringWithFormat:@"task_for_pid failed: kern_return_t=%d (%s).",
                          result, mach_error_string(result)];
    }
    return session;
}

+ (NSString *)displayNameForStatus:(EHProcessSessionStatus)status {
    switch (status) {
        case EHProcessSessionStatusDetached: return @"DETACHED";
        case EHProcessSessionStatusAttachedToSelf: return @"CONNECTED · SELF";
        case EHProcessSessionStatusAttached: return @"CONNECTED";
        case EHProcessSessionStatusPermissionDenied: return @"PERMISSION DENIED";
        case EHProcessSessionStatusProcessExited: return @"PROCESS EXITED";
        case EHProcessSessionStatusRejected: return @"REJECTED";
    }
    return @"UNKNOWN";
}
@end
