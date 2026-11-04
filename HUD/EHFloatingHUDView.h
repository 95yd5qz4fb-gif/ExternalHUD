#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EHMenuSection) {
    EHMenuSectionEnvironment = 0,
    EHMenuSectionCapabilities,
    EHMenuSectionDiagnostics
};

@interface EHFloatingHUDView : UIView
@property (nonatomic, assign, getter=isExpanded) BOOL expanded;
@property (nonatomic, copy, nullable) void (^onSectionSelected)(EHMenuSection section);
- (void)setDetailsText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
