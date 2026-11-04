#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EHCapabilityState) {
    EHCapabilityStateNotIntegrated = 0,
    EHCapabilityStateUnknown,
    EHCapabilityStateAvailable,
    EHCapabilityStateUnavailable
};

@interface EHCapabilityDescriptor : NSObject
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *details;
@property (nonatomic, assign, readonly) EHCapabilityState state;
- (instancetype)initWithName:(NSString *)name details:(NSString *)details state:(EHCapabilityState)state;
@end

@interface EHCapabilityRegistry : NSObject
+ (NSArray<EHCapabilityDescriptor *> *)descriptors;
@end

NS_ASSUME_NONNULL_END
