#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EHDeviceInfo : NSObject
@property (nonatomic, copy, readonly) NSString *machineIdentifier;
@property (nonatomic, copy, readonly) NSString *osVersion;
@property (nonatomic, copy, readonly) NSString *buildVersion;
// Compile-time Mach-O slice (arm64/arm64e), not a hardware capability verdict.
@property (nonatomic, copy, readonly) NSString *architecture;
@property (nonatomic, copy, readonly) NSString *appVersion;
+ (instancetype)currentInfo;
@end

NS_ASSUME_NONNULL_END
