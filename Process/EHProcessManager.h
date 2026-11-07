#import <Foundation/Foundation.h>
#import <mach/mach.h>
NS_ASSUME_NONNULL_BEGIN
@interface EHProcessTarget : NSObject
@property(nonatomic,assign,readonly) pid_t processIdentifier;
@property(nonatomic,copy,readonly) NSString *processName;
@property(nonatomic,copy,readonly) NSString *bundleIdentifier;
@property(nonatomic,copy,readonly) NSString *executablePath;
@property(nonatomic,assign,readonly,getter=isCurrentProcess) BOOL currentProcess;
@end
typedef NS_ENUM(NSInteger, EHProcessSessionStatus) {
 EHProcessSessionStatusDetached=0, EHProcessSessionStatusAttachedToSelf,
 EHProcessSessionStatusAttached, EHProcessSessionStatusPermissionDenied,
 EHProcessSessionStatusProcessExited, EHProcessSessionStatusRejected
};
@interface EHProcessSession : NSObject
@property(nonatomic,strong,readonly) EHProcessTarget *target;
@property(nonatomic,assign,readonly) EHProcessSessionStatus status;
@property(nonatomic,copy,readonly) NSString *detail;
@property(nonatomic,assign,readonly) mach_port_t taskPort;
@end
@interface EHProcessManager : NSObject
+ (EHProcessTarget *)currentProcess;
+ (NSArray<EHProcessTarget *> *)allProcesses;
+ (nullable EHProcessTarget *)targetForPID:(pid_t)pid;
+ (EHProcessSession *)attachToTarget:(EHProcessTarget *)target;
+ (NSString *)displayNameForStatus:(EHProcessSessionStatus)status;
@end
NS_ASSUME_NONNULL_END
