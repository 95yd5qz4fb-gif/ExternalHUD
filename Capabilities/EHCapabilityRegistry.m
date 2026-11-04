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
    // Metadata only: no exploit payloads, bypass routines, or kernel interaction.
    return @[
        [[EHCapabilityDescriptor alloc] initWithName:@"Kernel" details:@"No kernel backend integrated. Compatibility is not yet validated." state:EHCapabilityStateNotIntegrated],
        [[EHCapabilityDescriptor alloc] initWithName:@"PAC" details:@"No PAC component integrated. Status is intentionally not inferred from device model." state:EHCapabilityStateNotIntegrated],
        [[EHCapabilityDescriptor alloc] initWithName:@"PPL" details:@"No PPL component integrated. Status is intentionally not inferred from iOS version." state:EHCapabilityStateNotIntegrated]
    ];
}

@end
