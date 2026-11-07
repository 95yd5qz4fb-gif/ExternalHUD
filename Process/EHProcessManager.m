#import "EHProcessManager.h"
#import <mach/mach.h>
#import <unistd.h>

@interface EHProcessTarget ()
@property (nonatomic, assign, readwrite) pid_t processIdentifier;
@property (nonatomic, copy, readwrite) NSString *processName;
@property (nonatomic, copy, readwrite) NSString *bundleIdentifier;
@property (nonatomic, assign, readwrite, getter=isCurrentProcess) BOOL currentProcess;
@end

@implementation EHProcessTarget
@end

@interface EHProcessSession ()
@property (nonatomic, strong, readwrite) EHProcessTarget *target;
@property (nonatomic, assign, readwrite) EHProcessSessionStatus status;
@property (nonatomic, copy, readwrite) NSString *detail;
@end

@implementation EHProcessSession
@end

@implementation EHProcessManager

+ (EHProcessTarget *)currentProcess {
    EHProcessTarget *target = [EHProcessTarget new];
    target.processIdentifier = getpid();
    target.processName = NSProcessInfo.processInfo.processName ?: @"ExternalHUD";
    target.bundleIdentifier = NSBundle.mainBundle.bundleIdentifier ?: @"Unknown";
    target.currentProcess = YES;
    return target;
}

+ (EHProcessSession *)attachToTarget:(EHProcessTarget *)target {
    EHProcessSession *session = [EHProcessSession new];
    session.target = target ?: [self currentProcess];

    // The first backend is deliberately limited to this app's own task.
    // It validates the session lifecycle without obtaining another process's task port.
    if (!session.target.isCurrentProcess || session.target.processIdentifier != getpid()) {
        session.status = EHProcessSessionStatusBackendUnavailable;
        session.detail = @"No external-process backend is integrated for this target.";
        return session;
    }

    mach_port_t ownTask = mach_task_self();
    if (ownTask == MACH_PORT_NULL) {
        session.status = EHProcessSessionStatusRejected;
        session.detail = @"The current process task port is unavailable.";
        return session;
    }

    session.status = EHProcessSessionStatusAttachedToSelf;
    session.detail = @"Attached to ExternalHUD itself. External targets require a separately validated backend.";
    return session;
}

+ (NSString *)displayNameForStatus:(EHProcessSessionStatus)status {
    switch (status) {
        case EHProcessSessionStatusDetached: return @"DETACHED";
        case EHProcessSessionStatusAttachedToSelf: return @"SELF SESSION";
        case EHProcessSessionStatusBackendUnavailable: return @"BACKEND UNAVAILABLE";
        case EHProcessSessionStatusRejected: return @"REJECTED";
    }
    return @"UNKNOWN";
}

@end
