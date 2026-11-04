#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EHDeviceInfo : NSObject
@property (nonatomic, copy, readonly) NSString *machineIdentifier;
@property (nonatomic, copy, readonly) NSString *osVersion;
@property (nonatomic, copy, readonly) NSString *buildVersion;
@property (nonatomic, copy, readonly) NSString *architecture;
@property (nonatomic, copy, readonly) NSString *appVersion;
+ (instancetype)currentInfo;
@end

NS_ASSUME_NONNULL_END
