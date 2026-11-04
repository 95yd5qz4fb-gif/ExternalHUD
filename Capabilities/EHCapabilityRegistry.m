#import "EHCapabilityRegistry.h"

@implementation EHCapabilityDescriptor
- (instancetype)initWithName:(NSString *)name details:(NSString *)details state:(EHCapabilityState)state {
    self = [super init];
    if (self) {
        _name = [name copy];
        _details = [details copy];
        _state = state;
    }
    return self;
}
@end

@implementation EHCapabilityRegistry
+ (NSArray<EHCapabilityDescriptor *> *)descriptors {
    // Reference catalog only. These labels do not imply executable support or compatibility.
    return @[
        [[EHCapabilityDescriptor alloc] initWithName:@"Kernel" details:@"Kernel capability layer. No backend integrated." state:EHCapabilityStateNotIntegrated],
        [[EHCapabilityDescriptor alloc] initWithName:@"KFD" details:@"Kernel exploit research reference only; no payload or supported-build claims." state:EHCapabilityStateNotIntegrated],
        [[EHCapabilityDescriptor alloc] initWithName:@"DarkSword" details:@"Kernel exploit research reference only; no payload or supported-build claims." state:EHCapabilityStateNotIntegrated],
        [[EHCapabilityDescriptor alloc] initWithName:@"PAC" details:@"Separate pointer-authentication capability layer. No component integrated." state:EHCapabilityStateNotIntegrated],
        [[EHCapabilityDescriptor alloc] initWithName:@"PPL" details:@"Separate page-protection-layer capability. No component integrated." state:EHCapabilityStateNotIntegrated]
    ];
}
@end
