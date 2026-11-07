#import "EHHomeViewController.h"
#import "../System/EHDeviceInfo.h"
#import "../System/EHCompatibility.h"
#import "../Capabilities/EHCapabilityRegistry.h"
#import "../Diagnostics/EHDiagnostics.h"
#import "../Process/EHProcessManager.h"
#import "EHFloatingHUDView.h"

@interface EHHomeViewController ()
@property (nonatomic, strong) EHFloatingHUDView *floatingHUD;
@property (nonatomic, assign) BOOL didPositionFloatingHUD;
@property (nonatomic, strong) UILabel *processStatusLabel;
@end

@implementation EHHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.055 green:0.065 blue:0.09 alpha:1.0];
    [self buildInterface];
    self.floatingHUD = [[EHFloatingHUDView alloc] initWithFrame:CGRectMake(0, 0, 200, 38)];
    __weak EHHomeViewController *weakSelf = self;
    self.floatingHUD.onSectionSelected = ^(EHMenuSection section) {
        [weakSelf updateFloatingHUDForSection:section];
    };
    [self.view addSubview:self.floatingHUD];
}

- (void)updateFloatingHUDForSection:(EHMenuSection)section {
    EHDeviceInfo *device = EHDeviceInfo.currentInfo;
    switch (section) {
        case EHMenuSectionProcesses: {
            EHProcessTarget *target = EHProcessManager.currentProcess;
            EHProcessSession *session = [EHProcessManager attachToTarget:target];
            [self.floatingHUD setDetailsText:[NSString stringWithFormat:@"PID %d · %@\n%@", target.processIdentifier, target.processName, session.detail]];
            break;
        }
        case EHMenuSectionEnvironment:
            [self.floatingHUD setDetailsText:[NSString stringWithFormat:@"%@ · %@\niOS %@ · %@", device.machineIdentifier, device.architecture, device.osVersion, device.buildVersion]];
            break;
        case EHMenuSectionCapabilities:
            [self.floatingHUD setDetailsText:@"KERNEL · NOT INTEGRATED\nPAC / PPL · NOT INTEGRATED"];
            break;
        case EHMenuSectionDiagnostics: {
            NSDictionary *snapshot = EHDiagnostics.snapshot;
            NSString *memory = snapshot[@"App memory footprint"] ?: @"Unavailable";
            NSString *uptime = snapshot[@"System uptime"] ?: @"Unavailable";
            [self.floatingHUD setDetailsText:[NSString stringWithFormat:@"APP MEMORY · %@\nSYSTEM UPTIME · %@", memory, uptime]];
            break;
        }
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.didPositionFloatingHUD && self.floatingHUD) {
        CGFloat x = MAX(12.0, CGRectGetWidth(self.view.bounds) - 212.0);
        CGFloat y = MAX(20.0, CGRectGetHeight(self.view.bounds) - 126.0);
        self.floatingHUD.frame = CGRectMake(x, y, 200, 38);
        self.didPositionFloatingHUD = YES;
    }
}

- (UILabel *)label:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight color:(UIColor *)color {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (UIView *)cardWithTitle:(NSString *)title rows:(NSArray<NSString *> *)rows {
    UIView *card = [UIView new];
    card.backgroundColor = [UIColor colorWithWhite:1 alpha:0.065];
    card.layer.cornerRadius = 14;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.09].CGColor;

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 9;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14]
    ]];

    [stack addArrangedSubview:[self label:title size:16 weight:UIFontWeightSemibold color:UIColor.whiteColor]];
    for (NSString *row in rows) {
        [stack addArrangedSubview:[self label:row size:13 weight:UIFontWeightRegular color:[UIColor colorWithWhite:0.82 alpha:1]]];
    }
    return card;
}

- (void)buildInterface {
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16]
    ]];

    UIStackView *stack = [UIStackView new];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 13;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];

    EHDeviceInfo *device = EHDeviceInfo.currentInfo;
    [stack addArrangedSubview:[self label:@"EXTERNAL HUD" size:25 weight:UIFontWeightBold color:UIColor.whiteColor]];
    [stack addArrangedSubview:[self label:@"Process sessions · environment · capability modules" size:13 weight:UIFontWeightRegular color:[UIColor colorWithWhite:0.65 alpha:1]]];

    NSArray *deviceRows = @[
        [NSString stringWithFormat:@"Device: %@", device.machineIdentifier],
        [NSString stringWithFormat:@"iOS: %@ (build %@)", device.osVersion, device.buildVersion],
        [NSString stringWithFormat:@"Binary slice: %@", device.architecture],
        [NSString stringWithFormat:@"Compatibility: %@", [EHCompatibilityEvaluator displayNameForStatus:[EHCompatibilityEvaluator evaluateMachineIdentifier:device.machineIdentifier architecture:device.architecture osVersion:device.osVersion buildVersion:device.buildVersion rules:@[]]]],
        [NSString stringWithFormat:@"App: %@", device.appVersion]
    ];
    [stack addArrangedSubview:[self cardWithTitle:@"DEVICE ENVIRONMENT" rows:deviceRows]];

    EHProcessTarget *current = EHProcessManager.currentProcess;
    EHProcessSession *session = [EHProcessManager attachToTarget:current];
    [stack addArrangedSubview:[self cardWithTitle:@"PROCESS SESSION" rows:@[
        [NSString stringWithFormat:@"Current process: %@ (PID %d)", current.processName, current.processIdentifier],
        [NSString stringWithFormat:@"Bundle: %@", current.bundleIdentifier],
        [NSString stringWithFormat:@"Session: %@", [EHProcessManager displayNameForStatus:session.status]],
        session.detail,
        @"External process discovery and kernel-backed attachment are not yet implemented."
    ]]];

    NSMutableArray *capabilityRows = [NSMutableArray array];
    for (EHCapabilityDescriptor *item in EHCapabilityRegistry.descriptors) {
        [capabilityRows addObject:[NSString stringWithFormat:@"%@ · NOT INTEGRATED\n%@", item.name.uppercaseString, item.details]];
    }
    [stack addArrangedSubview:[self cardWithTitle:@"CAPABILITY REGISTRY" rows:capabilityRows]];

    NSDictionary *diagnostics = EHDiagnostics.snapshot;
    NSMutableArray *diagnosticRows = [NSMutableArray array];
    for (NSString *key in [[diagnostics allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [diagnosticRows addObject:[NSString stringWithFormat:@"%@: %@", key, diagnostics[key]]];
    }
    [stack addArrangedSubview:[self cardWithTitle:@"LOCAL DIAGNOSTICS" rows:diagnosticRows]];

    [stack addArrangedSubview:[self label:@"Process session currently validates only ExternalHUD's own task. Compatibility remains UNTESTED until an exact device + iOS build combination has been verified on hardware." size:11 weight:UIFontWeightRegular color:[UIColor colorWithWhite:0.58 alpha:1]]];
}

@end
