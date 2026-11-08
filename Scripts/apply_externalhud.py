#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "Dopamine/Application/Dopamine"
MAIN = APP / "UI/DOMainViewController.m"
ENT = APP / "Dopamine.entitlements"
INFO = APP / "Info.plist"
PBX = ROOT / "Dopamine/Application/Dopamine.xcodeproj/project.pbxproj"

src = MAIN.read_text()
if "EHProcessListViewController" not in src:
    src = src.replace(
        '#import <libjailbreak/libjailbreak.h>',
        '#import <libjailbreak/libjailbreak.h>\n'
        '#import <libjailbreak/kernel.h>\n'
        '#import <libjailbreak/primitives.h>\n'
        '#import <libjailbreak/util.h>\n'
        '#import <libproc.h>\n'
        '#import <dispatch/dispatch.h>'
    )
    marker = "@interface DOMainViewController ()"
    process_ui = r'''
@interface EHProcessItem : NSObject
@property(nonatomic, assign) pid_t pid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *path;
@end
@implementation EHProcessItem
@end

@interface EHProcessListViewController : UITableViewController
@property(nonatomic, strong) NSArray<EHProcessItem *> *processes;
@property(nonatomic, copy) NSString *connectedProcess;
@property(nonatomic, assign) BOOL kernelReady;
@end

@implementation EHProcessListViewController

- (BOOL)initializeKernelBackend {
    static dispatch_once_t onceToken;
    static int initResult = -1;
    dispatch_once(&onceToken, ^{
        initResult = jbclient_initialize_primitives();
    });
    self.kernelReady = (initResult == 0);
    return self.kernelReady;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Processes";
    self.tableView.rowHeight = 64.0;
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                     target:self action:@selector(reloadProcesses)];
    [self reloadProcesses];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadProcesses];
}

- (void)reloadProcesses {
    if (![self initializeKernelBackend]) {
        self.processes = @[];
        self.navigationItem.prompt = @"Kernel primitives unavailable";
        [self.tableView reloadData];
        return;
    }

    NSMutableArray<EHProcessItem *> *items = [NSMutableArray array];
    proc_iterate(^(uint64_t kernelProc, bool *stop) {
        pid_t pid = (pid_t)kread32(kernelProc + koffsetof(proc, pid));
        if (pid <= 0) return;

        char nameBuffer[256] = {0};
        char pathBuffer[4096] = {0};
        proc_name(pid, nameBuffer, sizeof(nameBuffer));
        proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));

        EHProcessItem *item = [EHProcessItem new];
        item.pid = pid;
        item.name = nameBuffer[0] ? [NSString stringWithUTF8String:nameBuffer]
                                  : [NSString stringWithFormat:@"pid-%d", pid];
        item.path = pathBuffer[0] ? [NSString stringWithUTF8String:pathBuffer] : @"";
        [items addObject:item];
    });

    [items sortUsingComparator:^NSComparisonResult(EHProcessItem *a, EHProcessItem *b) {
        return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    self.processes = items;
    self.navigationItem.prompt = self.connectedProcess.length
        ? [NSString stringWithFormat:@"Kernel task resolved: %@", self.connectedProcess]
        : [NSString stringWithFormat:@"Kernel proc traversal · %lu processes", (unsigned long)items.count];
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.processes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseID = @"EHProcessCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseID];
    EHProcessItem *item = self.processes[indexPath.row];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = item.path.length
        ? [NSString stringWithFormat:@"PID %d  ·  %@", item.pid, item.path]
        : [NSString stringWithFormat:@"PID %d", item.pid];
    cell.detailTextLabel.numberOfLines = 2;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    EHProcessItem *item = self.processes[indexPath.row];

    if (![self initializeKernelBackend]) {
        [self showConnectionResult:@"Kernel backend unavailable" detail:@"Dopamine kernel primitives could not be initialized."];
        return;
    }

    // Resolve both XNU objects through Dopamine's kernel-backed helpers.
    // The raw kernel address is deliberately not exposed to UI or persisted.
    uint64_t kernelProc = proc_find(item.pid);
    if (!kernelProc) {
        [self showConnectionResult:@"Kernel lookup failed"
                            detail:[NSString stringWithFormat:@"proc_find(%d) returned NULL. The process may have exited.", item.pid]];
        return;
    }

    uint64_t kernelTask = proc_task(kernelProc);
    proc_rele(kernelProc);

    if (!kernelTask) {
        [self showConnectionResult:@"Kernel task lookup failed"
                            detail:[NSString stringWithFormat:@"proc_task for PID %d returned NULL.", item.pid]];
        return;
    }

    self.connectedProcess = [NSString stringWithFormat:@"%@ (PID %d)", item.name, item.pid];
    self.navigationItem.prompt = [NSString stringWithFormat:@"Kernel task resolved: %@", self.connectedProcess];
    [self showConnectionResult:@"Kernel task resolved"
                        detail:[NSString stringWithFormat:
                            @"Dopamine proc_find() and proc_task() both succeeded for %@. This is a kernel task object, not a Mach task port.",
                            self.connectedProcess]];
}

- (void)showConnectionResult:(NSString *)title detail:(NSString *)detail {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:detail
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

'''
    if marker not in src:
        raise SystemExit("DOMainViewController insertion point not found")
    src = src.replace(marker, process_ui + marker, 1)

    action_marker = "    ] delegate:self];"
    action = r'''        [UIAction actionWithTitle:@"Processes"
                            image:[UIImage systemImageNamed:@"list.bullet"]
                       identifier:@"externalhud-processes"
                          handler:^(__kindof UIAction * _Nonnull action) {
            [self.navigationController pushViewController:[[EHProcessListViewController alloc] initWithStyle:UITableViewStyleInsetGrouped]
                                                 animated:YES];
        }],
'''
    if action_marker not in src:
        raise SystemExit("Dopamine action menu insertion point not found")
    src = src.replace(action_marker, ",\n" + action + action_marker, 1)
    MAIN.write_text(src)

# The process manager no longer requests Mach task ports.
ent = ENT.read_text()
ent = re.sub(r'\s*<key>task_for_pid-allow</key>\s*<true/>', '', ent)
ent = re.sub(r'\s*<key>com.apple.system-task-ports</key>\s*<true/>', '', ent)
ENT.write_text(ent)

info = INFO.read_text()
if "CFBundleDisplayName" not in info:
    info = info.replace("<dict>", "<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>ExternalHUD</string>", 1)
else:
    info = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>).*?(</string>)", r"\1ExternalHUD\2", info, count=1)
INFO.write_text(info)

pbx = PBX.read_text().replace("com.opa334.Dopamine", "com.gira983.ExternalHUD")
PBX.write_text(pbx)
print("ExternalHUD now enumerates proc objects and resolves task objects through Dopamine kernel helpers.")
