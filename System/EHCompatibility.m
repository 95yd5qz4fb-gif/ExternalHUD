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

+ (BOOL)isValidVersionString:(NSString *)version {
    if (version.length == 0 ||
        ![version isEqualToString:[version stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]] ||
        [version hasPrefix:@"."] || [version hasSuffix:@"."] ||
        [version containsString:@".."]) {
        return NO;
    }

    NSCharacterSet *nonDigits = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
    if ([version rangeOfCharacterFromSet:nonDigits].location != NSNotFound) {
        return NO;
    }

    for (NSString *component in [version componentsSeparatedByString:@"."]) {
        if (component.length == 0) return NO;
    }
    return YES;
}

+ (BOOL)isValidBuildIdentifier:(NSString *)buildIdentifier {
    if (buildIdentifier.length == 0 || buildIdentifier.length > 64 ||
        ![buildIdentifier isEqualToString:[buildIdentifier stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]]) {
        return NO;
    }
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._-"] invertedSet];
    return [buildIdentifier rangeOfCharacterFromSet:invalid].location == NSNotFound;
}

+ (EHCompatibilityStatus)evaluateMachineIdentifier:(NSString *)machineIdentifier
                                      architecture:(NSString *)architecture
                                         osVersion:(NSString *)osVersion
                                      buildVersion:(NSString *)buildVersion
                                             rules:(NSArray<EHCompatibilityRule *> *)rules {
    BOOL validArchitecture = [architecture isEqualToString:@"arm64"] || [architecture isEqualToString:@"arm64e"];
    if (machineIdentifier.length == 0 || machineIdentifier.length > 64 ||
        !validArchitecture || ![self isValidVersionString:osVersion] ||
        ![self isValidBuildIdentifier:buildVersion] || rules.count == 0) {
        return EHCompatibilityStatusUnknown;
    }

    BOOL foundMatch = NO;
    EHCompatibilityStatus matchedStatus = EHCompatibilityStatusUnknown;

    for (EHCompatibilityRule *rule in rules) {
        if (rule.machineIdentifier.length == 0 || rule.machineIdentifier.length > 64 ||
            !([rule.architecture isEqualToString:@"arm64"] || [rule.architecture isEqualToString:@"arm64e"]) ||
            ![self isValidVersionString:rule.minimumOSVersion] ||
            ![self isValidVersionString:rule.maximumOSVersion] ||
            rule.testedBuilds.count == 0 ||
            (rule.status != EHCompatibilityStatusSupported && rule.status != EHCompatibilityStatusUnsupported)) {
            continue;
        }

        if ([rule.minimumOSVersion compare:rule.maximumOSVersion options:NSNumericSearch] == NSOrderedDescending) {
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
