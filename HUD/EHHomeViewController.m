#import "EHHomeViewController.h"
#import "../System/EHDeviceInfo.h"
#import "../System/EHCompatibility.h"
#import "../Capabilities/EHCapabilityRegistry.h"
#import "../Diagnostics/EHDiagnostics.h"
#import "../Process/EHProcessManager.h"
#import "EHFloatingHUDView.h"
#import <UIKit/UIKit.h>

@interface EHHomeViewController ()
@property (nonatomic, strong) EHFloatingHUDView *floatingHUD;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, assign) BOOL didPositionFloatingHUD;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (!self.didPositionFloatingHUD && self.floatingHUD) {
        CGFloat x = MAX(12.0, CGRectGetWidth(self.view.bounds) - 212.0);
        CGFloat y = MAX(20.0, CGRectGetHeight(self.view.bounds) - 126.0);
        self.floatingHUD.frame = CGRectMake(x, y, 200, 38);
        self.didPositionFloatingHUD = YES;
    }
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
            [self.floatingHUD setDetailsText:[NSString stringWithFormat:@"MEMORY · %@\nCPU · %@", snapshot[@"App memory footprint"] ?: @"N/A", snapshot[@"App CPU"] ?: @"N/A"]];
            break;
        }
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

- (UIButton *)actionButton:(NSString *)title action:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = [UIColor colorWithRed:0.18 green:0.42 blue:0.78 alpha:1];
    button.layer.cornerRadius = 10;
    button.contentEdgeInsets = UIEdgeInsetsMake(11, 14, 11, 14);
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildInterface {
    [self.contentScrollView removeFromSuperview];
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    self.contentScrollView = scroll;
    [self.view insertSubview:scroll atIndex:0];
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
    UIStackView *actions = [UIStackView new];
    actions.axis = UILayoutConstraintAxisHorizontal;
    actions.spacing = 9;
    actions.distribution = UIStackViewDistributionFillEqually;
    [actions addArrangedSubview:[self actionButton:@"VERIFY SELF SESSION" action:@selector(verifySelfSession)]];
    [actions addArrangedSubview:[self actionButton:@"COPY REPORT" action:@selector(copyDiagnosticReport)]];
    [stack addArrangedSubview:actions];

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
        @"External process discovery and kernel-backed attachment are not implemented."
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
    [stack addArrangedSubview:[self cardWithTitle:@"LIVE APP DIAGNOSTICS" rows:diagnosticRows]];
    [stack addArrangedSubview:[self label:@"Pull down to refresh. The process session validates only ExternalHUD's own task. Compatibility remains UNTESTED until an exact device + iOS build combination has been verified on hardware." size:11 weight:UIFontWeightRegular color:[UIColor colorWithWhite:0.58 alpha:1]]];

    UIRefreshControl *refresh = [UIRefreshControl new];
    [refresh addTarget:self action:@selector(refreshDashboard:) forControlEvents:UIControlEventValueChanged];
    [scroll addSubview:refresh];
}

- (void)refreshDashboard:(UIRefreshControl *)sender {
    [self buildInterface];
    [sender endRefreshing];
}

- (void)verifySelfSession {
    EHProcessTarget *target = EHProcessManager.currentProcess;
    EHProcessSession *session = [EHProcessManager attachToTarget:target];
    NSString *message = [NSString stringWithFormat:@"PID: %d\nBundle: %@\nStatus: %@\n\n%@", target.processIdentifier, target.bundleIdentifier, [EHProcessManager displayNameForStatus:session.status], session.detail];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Process session test" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)copyDiagnosticReport {
    EHDeviceInfo *device = EHDeviceInfo.currentInfo;
    EHProcessTarget *target = EHProcessManager.currentProcess;
    EHProcessSession *session = [EHProcessManager attachToTarget:target];
    NSDictionary *snapshot = EHDiagnostics.snapshot;
    NSMutableString *report = [NSMutableString stringWithString:@"ExternalHUD diagnostic report\n"];
    [report appendFormat:@"Device: %@\niOS: %@ (%@)\nArchitecture: %@\n", device.machineIdentifier, device.osVersion, device.buildVersion, device.architecture];
    [report appendFormat:@"Process: %@ (%d)\nBundle: %@\nSession: %@\n", target.processName, target.processIdentifier, target.bundleIdentifier, [EHProcessManager displayNameForStatus:session.status]];
    for (NSString *key in [[snapshot allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        [report appendFormat:@"%@: %@\n", key, snapshot[key]];
    }
    UIPasteboard.generalPasteboard.string = report;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Report copied" message:@"Diagnostic report copied to the clipboard." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
