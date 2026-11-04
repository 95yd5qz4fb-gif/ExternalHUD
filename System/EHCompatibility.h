#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EHCompatibilityStatus) {
    EHCompatibilityStatusUnknown = 0,
    EHCompatibilityStatusSupported,
    EHCompatibilityStatusUnsupported
};

@interface EHCompatibilityRule : NSObject
@property (nonatomic, copy, readonly) NSString *machineIdentifier;
@property (nonatomic, copy, readonly) NSString *architecture;
@property (nonatomic, copy, readonly) NSString *minimumOSVersion;
@property (nonatomic, copy, readonly) NSString *maximumOSVersion;
@property (nonatomic, copy, readonly) NSSet<NSString *> *testedBuilds;
@property (nonatomic, assign, readonly) EHCompatibilityStatus status;

- (instancetype)initWithMachineIdentifier:(NSString *)machineIdentifier
                             architecture:(NSString *)architecture
                          minimumOSVersion:(NSString *)minimumOSVersion
                          maximumOSVersion:(NSString *)maximumOSVersion
                              testedBuilds:(NSSet<NSString *> *)testedBuilds
                                    status:(EHCompatibilityStatus)status;
@end

@interface EHCompatibilityEvaluator : NSObject
+ (EHCompatibilityStatus)evaluateMachineIdentifier:(NSString *)machineIdentifier
                                      architecture:(NSString *)architecture
                                         osVersion:(NSString *)osVersion
                                      buildVersion:(NSString *)buildVersion
                                             rules:(NSArray<EHCompatibilityRule *> *)rules;
+ (NSString *)displayNameForStatus:(EHCompatibilityStatus)status;
@end

NS_ASSUME_NONNULL_END
