#import "EHHomeViewController.h"
#import "../System/EHDeviceInfo.h"
#import "../Diagnostics/EHDiagnostics.h"
#import "../Process/EHProcessManager.h"
#import "EHFloatingHUDView.h"
@interface EHHomeViewController ()
@property(nonatomic,strong) EHFloatingHUDView *floatingHUD;
@property(nonatomic,strong) UIScrollView *contentScrollView;
@property(nonatomic,strong) UIStackView *processRows;
@property(nonatomic,strong) UILabel *processCount;
@property(nonatomic,strong) EHProcessSession *activeSession;
@property(nonatomic,assign) BOOL didPositionFloatingHUD;
@end
@implementation EHHomeViewController
- (void)viewDidLoad { [super viewDidLoad]; self.view.backgroundColor=[UIColor colorWithRed:.055 green:.065 blue:.09 alpha:1]; [self buildInterface]; self.floatingHUD=[[EHFloatingHUDView alloc]initWithFrame:CGRectMake(0,0,200,38)]; __weak typeof(self) w=self; self.floatingHUD.onSectionSelected=^(EHMenuSection s){[w updateHUD:s];}; [self.view addSubview:self.floatingHUD]; }
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; if(!self.didPositionFloatingHUD&&self.floatingHUD){self.floatingHUD.frame=CGRectMake(MAX(12,CGRectGetWidth(self.view.bounds)-212),MAX(20,CGRectGetHeight(self.view.bounds)-126),200,38);self.didPositionFloatingHUD=YES;} }
- (UILabel *)label:(NSString *)s size:(CGFloat)n { UILabel *l=[UILabel new];l.text=s;l.font=[UIFont systemFontOfSize:n];l.textColor=UIColor.whiteColor;l.numberOfLines=0;return l; }
- (void)updateHUD:(EHMenuSection)section { if(section==EHMenuSectionProcesses){EHProcessTarget *t=self.activeSession.target?:EHProcessManager.currentProcess;[self.floatingHUD setDetailsText:[NSString stringWithFormat:@"PID %d · %@\n%@",t.processIdentifier,t.processName,self.activeSession?[EHProcessManager displayNameForStatus:self.activeSession.status]:@"NOT CONNECTED"]];}else if(section==EHMenuSectionEnvironment){EHDeviceInfo *d=EHDeviceInfo.currentInfo;[self.floatingHUD setDetailsText:[NSString stringWithFormat:@"%@ · %@\niOS %@ · %@",d.machineIdentifier,d.architecture,d.osVersion,d.buildVersion]];}else if(section==EHMenuSectionDiagnostics){NSDictionary *d=EHDiagnostics.snapshot;[self.floatingHUD setDetailsText:[NSString stringWithFormat:@"MEMORY · %@\nCPU · %@",d[@"App memory footprint"]?:@"N/A",d[@"App CPU"]?:@"N/A"]];}else [self.floatingHUD setDetailsText:@"LOCAL PROCESS ENUMERATION\nMACH TASK PORT REQUEST"]; }
- (void)addTitle:(NSString *)title toStack:(UIStackView *)stack { UILabel *l=[self label:title size:16];l.font=[UIFont boldSystemFontOfSize:16];[stack addArrangedSubview:l]; }
- (void)buildInterface {
 [self.contentScrollView removeFromSuperview]; UIScrollView *scroll=[UIScrollView new];scroll.translatesAutoresizingMaskIntoConstraints=NO;scroll.alwaysBounceVertical=YES;self.contentScrollView=scroll;[self.view insertSubview:scroll atIndex:0];
 [NSLayoutConstraint activateConstraints:@[[scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12],[scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],[scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],[scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16]]];
 UIStackView *root=[UIStackView new];root.axis=UILayoutConstraintAxisVertical;root.spacing=13;root.translatesAutoresizingMaskIntoConstraints=NO;[scroll addSubview:root];
 [NSLayoutConstraint activateConstraints:@[[root.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],[root.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],[root.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],[root.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],[root.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]]];
 UILabel *head=[self label:@"EXTERNAL HUD · PROCESS MANAGER" size:22];head.font=[UIFont boldSystemFontOfSize:22];[root addArrangedSubview:head];
 EHDeviceInfo *d=EHDeviceInfo.currentInfo;[root addArrangedSubview:[self label:[NSString stringWithFormat:@"%@ · iOS %@ (%@) · %@",d.machineIdentifier,d.osVersion,d.buildVersion,d.architecture] size:12]];
 UIButton *refresh=[UIButton buttonWithType:UIButtonTypeSystem];[refresh setTitle:@"REFRESH PROCESS LIST" forState:UIControlStateNormal];refresh.backgroundColor=[UIColor colorWithRed:.18 green:.42 blue:.78 alpha:1];refresh.layer.cornerRadius=9;refresh.contentEdgeInsets=UIEdgeInsetsMake(12,14,12,14);[refresh setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];[refresh addTarget:self action:@selector(reloadProcesses) forControlEvents:UIControlEventTouchUpInside];[root addArrangedSubview:refresh];
 UIView *card=[UIView new];card.backgroundColor=[UIColor colorWithWhite:1 alpha:.065];card.layer.cornerRadius=14;UIStackView *inside=[UIStackView new];inside.axis=UILayoutConstraintAxisVertical;inside.spacing=8;inside.translatesAutoresizingMaskIntoConstraints=NO;[card addSubview:inside];
 [NSLayoutConstraint activateConstraints:@[[inside.topAnchor constraintEqualToAnchor:card.topAnchor constant:14],[inside.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-14],[inside.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:14],[inside.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-14]]];
 [self addTitle:@"RUNNING PROCESSES" toStack:inside];self.processCount=[self label:@"Scanning…" size:11];[inside addArrangedSubview:self.processCount];self.processRows=[UIStackView new];self.processRows.axis=UILayoutConstraintAxisVertical;self.processRows.spacing=5;[inside addArrangedSubview:self.processRows];[root addArrangedSubview:card];
 [root addArrangedSubview:[self label:@"Select a PID to request its Mach task port. iOS may deny access depending on jailbreak state and entitlements. A successful connection does not read or modify process memory." size:11]];
 NSDictionary *diag=EHDiagnostics.snapshot;NSMutableArray *lines=[NSMutableArray array];for(NSString *k in [[diag allKeys] sortedArrayUsingSelector:@selector(compare:)])[lines addObject:[NSString stringWithFormat:@"%@: %@",k,diag[k]]];[root addArrangedSubview:[self label:[lines componentsJoinedByString:@"\n"] size:11]];
 [self reloadProcesses];
}
- (void)reloadProcesses {
 for(UIView *v in self.processRows.arrangedSubviews){[self.processRows removeArrangedSubview:v];[v removeFromSuperview];}
 NSArray<EHProcessTarget *> *list=EHProcessManager.allProcesses;self.processCount.text=[NSString stringWithFormat:@"%lu visible processes",(unsigned long)list.count];
 if(!list.count){[self.processRows addArrangedSubview:[self label:@"No process entries returned by libproc." size:12]];return;}
 for(EHProcessTarget *t in list){UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=t.processIdentifier;b.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;b.backgroundColor=[UIColor colorWithWhite:1 alpha:.05];b.layer.cornerRadius=7;b.contentEdgeInsets=UIEdgeInsetsMake(9,10,9,10);[b setTitle:[NSString stringWithFormat:@"%d  %@\n%@",t.processIdentifier,t.processName,t.bundleIdentifier] forState:UIControlStateNormal];[b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];b.titleLabel.font=[UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightRegular];b.titleLabel.numberOfLines=2;[b addTarget:self action:@selector(connectProcess:) forControlEvents:UIControlEventTouchUpInside];[self.processRows addArrangedSubview:b];}
}
- (void)connectProcess:(UIButton *)sender {
 EHProcessTarget *t=[EHProcessManager targetForPID:(pid_t)sender.tag];if(!t){[self show:@"Process disappeared" message:@"Refresh the process list and select it again."];[self reloadProcesses];return;}
 self.activeSession=[EHProcessManager attachToTarget:t];[self updateHUD:EHMenuSectionProcesses];
 [self show:@"Connection result" message:[NSString stringWithFormat:@"PID: %d\nName: %@\nBundle: %@\nPath: %@\n\n%@\n%@",t.processIdentifier,t.processName,t.bundleIdentifier,t.executablePath,[EHProcessManager displayNameForStatus:self.activeSession.status],self.activeSession.detail]];
}
- (void)show:(NSString *)title message:(NSString *)message {UIAlertController *a=[UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];[self presentViewController:a animated:YES completion:nil];}
@end
