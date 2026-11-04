#import "EHCompatibility.h"

@implementation EHCompatibilityRule

- (instancetype)initWithMachineIdentifier:(NSString *)machineIdentifier
                             architecture:(NSString *)architecture
                           minimumOSVersion:(NSString *)minimumOSVersion
                           maximumOSVersion:(NSString *)maximumOSVersion
                               testedBuilds:(NSSet<NSString *> *)testedBuilds
                                     status:(EHCompatibilityStatus)status {
    self = [super init];
    if (self) {
        _machineIdentifier = [machineIdentifier copy] ?: @"";
        _architecture = [architecture copy] ?: @"";
        _minimumOSVersion = [minimumOSVersion copy] ?: @"";
        _maximumOSVersion = [maximumOSVersion copy] ?: @"";
        _testedBuilds = [testedBuilds copy] ?: [NSSet set];
        _status = status;
    }
    return self;
}

@end

@implementation EHCompatibilityEvaluator

+ (EHCompatibilityStatus)evaluateMachineIdentifier:(NSString *)machineIdentifier
                                      architecture:(NSString *)architecture
                                         osVersion:(NSString *)osVersion
                                      buildVersion:(NSString *)buildVersion
                                             rules:(NSArray<EHCompatibilityRule *> *)rules {
    if (machineIdentifier.length == 0 || architecture.length == 0 ||
        osVersion.length == 0 || buildVersion.length == 0 || rules.count == 0) {
        return EHCompatibilityStatusUnknown;
    }

    BOOL foundMatch = NO;
    EHCompatibilityStatus matchedStatus = EHCompatibilityStatusUnknown;

    for (EHCompatibilityRule *rule in rules) {
        if (rule.machineIdentifier.length == 0 || rule.architecture.length == 0 ||
            rule.minimumOSVersion.length == 0 || rule.maximumOSVersion.length == 0 ||
            rule.testedBuilds.count == 0) {
            continue;
        }

        if (![rule.machineIdentifier isEqualToString:machineIdentifier] ||
            ![rule.architecture isEqualToString:architecture] ||
            ![rule.testedBuilds containsObject:buildVersion]) {
            continue;
        }

        NSComparisonResult lowerBound = [osVersion compare:rule.minimumOSVersion options:NSNumericSearch];
        NSComparisonResult upperBound = [osVersion compare:rule.maximumOSVersion options:NSNumericSearch];
        if (lowerBound == NSOrderedAscending || upperBound == NSOrderedDescending) {
            continue;
        }

        if (foundMatch && matchedStatus != rule.status) {
            // Conflicting records are ambiguous; never choose the more permissive one.
            return EHCompatibilityStatusUnknown;
        }

        foundMatch = YES;
        matchedStatus = rule.status;
    }

    return foundMatch ? matchedStatus : EHCompatibilityStatusUnknown;
}

+ (NSString *)displayNameForStatus:(EHCompatibilityStatus)status {
    switch (status) {
        case EHCompatibilityStatusSupported:
            return @"SUPPORTED";
        case EHCompatibilityStatusUnsupported:
            return @"UNSUPPORTED";
        case EHCompatibilityStatusUnknown:
        default:
            return @"UNTESTED";
    }
}

@end
