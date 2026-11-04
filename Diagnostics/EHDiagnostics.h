#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EHDiagnostics : NSObject
+ (NSDictionary<NSString *, NSString *> *)snapshot;
@end

NS_ASSUME_NONNULL_END
