#import "EHFloatingHUDView.h"

@interface EHFloatingHUDView ()
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailsLabel;
@property (nonatomic, strong) UIButton *toggleButton;
@property (nonatomic, copy) NSArray<UIButton *> *sectionButtons;
@end

@implementation EHFloatingHUDView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.10 green:0.13 blue:0.19 alpha:0.97];
        self.layer.cornerRadius = 19.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.16].CGColor;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.24;
        self.layer.shadowRadius = 12.0;
        self.layer.shadowOffset = CGSizeMake(0, 5);
        self.clipsToBounds = NO;
        self.accessibilityLabel = @"ExternalHUD floating panel";

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, 148, 38)];
        _titleLabel.text = @"EXTERNAL HUD";
        _titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.userInteractionEnabled = YES;
        [self addSubview:_titleLabel];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        pan.cancelsTouchesInView = NO;
        [_titleLabel addGestureRecognizer:pan];

        _toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggleButton.frame = CGRectMake(164, 3, 32, 32);
        _toggleButton.layer.cornerRadius = 16;
        _toggleButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
        [_toggleButton setTitle:@"+" forState:UIControlStateNormal];
        [_toggleButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _toggleButton.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
        [_toggleButton addTarget:self action:@selector(toggleExpanded) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_toggleButton];

        _detailsLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 42, 176, 46)];
        _detailsLabel.text = @"PROCESS SESSION\nChoose a section below";
        _detailsLabel.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
        _detailsLabel.textColor = [UIColor colorWithWhite:0.86 alpha:1];
        _detailsLabel.numberOfLines = 2;
        _detailsLabel.hidden = YES;
        [self addSubview:_detailsLabel];

        NSArray<NSString *> *titles = @[@"PROC", @"DEVICE", @"CAPS", @"DIAG"];
        NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:titles.count];
        for (NSUInteger index = 0; index < titles.count; index++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectMake(7 + (CGFloat)index * 48, 94, 43, 27);
            button.tag = (NSInteger)index;
            button.layer.cornerRadius = 7;
            button.backgroundColor = [UIColor colorWithWhite:1 alpha:0.11];
            [button setTitle:titles[index] forState:UIControlStateNormal];
            [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:8 weight:UIFontWeightBold];
            [button addTarget:self action:@selector(selectSection:) forControlEvents:UIControlEventTouchUpInside];
            button.hidden = YES;
            [self addSubview:button];
            [buttons addObject:button];
        }
        _sectionButtons = [buttons copy];
        self.expanded = NO;
    }
    return self;
}

- (void)setExpanded:(BOOL)expanded {
    _expanded = expanded;
    self.frame = (CGRect){self.frame.origin, CGSizeMake(200, expanded ? 130 : 38)};
    self.layer.cornerRadius = expanded ? 15.0 : 19.0;
    self.detailsLabel.hidden = !expanded;
    for (UIButton *button in self.sectionButtons) button.hidden = !expanded;
    [self.toggleButton setTitle:(expanded ? @"−" : @"+") forState:UIControlStateNormal];
    self.accessibilityValue = expanded ? @"Expanded" : @"Collapsed";
}

- (void)setDetailsText:(NSString *)text {
    self.detailsLabel.text = text.length > 180 ? [[text substringToIndex:177] stringByAppendingString:@"…"] : text;
}

- (void)toggleExpanded { self.expanded = !self.isExpanded; }

- (void)selectSection:(UIButton *)sender {
    if (self.onSectionSelected) self.onSectionSelected((EHMenuSection)sender.tag);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *container = self.superview;
    if (!container) return;
    CGPoint translation = [gesture translationInView:container];
    CGRect nextFrame = self.frame;
    nextFrame.origin.x += translation.x;
    nextFrame.origin.y += translation.y;
    CGFloat maxX = MAX(0, CGRectGetWidth(container.bounds) - CGRectGetWidth(nextFrame));
    CGFloat maxY = MAX(0, CGRectGetHeight(container.bounds) - CGRectGetHeight(nextFrame));
    nextFrame.origin.x = MIN(MAX(0, nextFrame.origin.x), maxX);
    nextFrame.origin.y = MIN(MAX(0, nextFrame.origin.y), maxY);
    self.frame = nextFrame;
    [gesture setTranslation:CGPointZero inView:container];
}

@end
