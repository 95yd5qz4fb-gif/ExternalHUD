#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EHProcessTarget : NSObject
@property (nonatomic, assign, readonly) pid_t processIdentifier;
@property (nonatomic, copy, readonly) NSString *processName;
@property (nonatomic, copy, readonly) NSString *bundleIdentifier;
@property (nonatomic, assign, readonly, getter=isCurrentProcess) BOOL currentProcess;
@end

typedef NS_ENUM(NSInteger, EHProcessSessionStatus) {
    EHProcessSessionStatusDetached = 0,
    EHProcessSessionStatusAttachedToSelf,
    EHProcessSessionStatusBackendUnavailable,
    EHProcessSessionStatusRejected
};

@interface EHProcessSession : NSObject
@property (nonatomic, strong, readonly) EHProcessTarget *target;
@property (nonatomic, assign, readonly) EHProcessSessionStatus status;
@property (nonatomic, copy, readonly) NSString *detail;
@end

@interface EHProcessManager : NSObject
+ (EHProcessTarget *)currentProcess;
+ (EHProcessSession *)attachToTarget:(EHProcessTarget *)target;
+ (NSString *)displayNameForStatus:(EHProcessSessionStatus)status;
@end

NS_ASSUME_NONNULL_END
