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
        '#import <libjailbreak/libjailbreak.h>\n#import <libproc.h>\n#import <mach/mach.h>\n#import <unistd.h>'
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
@property(nonatomic, assign) mach_port_t connectedTask;
@property(nonatomic, copy) NSString *connectedProcess;
@end

@implementation EHProcessListViewController
- (void)dealloc {
    if (self.connectedTask != MACH_PORT_NULL) {
        mach_port_deallocate(mach_task_self(), self.connectedTask);
        self.connectedTask = MACH_PORT_NULL;
    }
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
    int count = proc_listallpids(NULL, 0);
    if (count <= 0) {
        self.processes = @[];
        [self.tableView reloadData];
        return;
    }
    pid_t *pids = calloc((size_t)count + 32, sizeof(pid_t));
    if (!pids) return;
    int actual = proc_listallpids(pids, (int)(((size_t)count + 32) * sizeof(pid_t)));
    NSMutableArray<EHProcessItem *> *items = [NSMutableArray array];
    for (int i = 0; i < actual; i++) {
        pid_t pid = pids[i];
        if (pid <= 0) continue;
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
    }
    free(pids);
    [items sortUsingComparator:^NSComparisonResult(EHProcessItem *a, EHProcessItem *b) {
        return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    self.processes = items;
    self.navigationItem.prompt = self.connectedProcess.length
        ? [NSString stringWithFormat:@"Connected: %@", self.connectedProcess]
        : [NSString stringWithFormat:@"%lu visible processes", (unsigned long)items.count];
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
    mach_port_t task = MACH_PORT_NULL;
    kern_return_t kr = task_for_pid(mach_task_self(), item.pid, &task);
    if (kr == KERN_SUCCESS && task != MACH_PORT_NULL) {
        if (self.connectedTask != MACH_PORT_NULL)
            mach_port_deallocate(mach_task_self(), self.connectedTask);
        self.connectedTask = task;
        self.connectedProcess = [NSString stringWithFormat:@"%@ (PID %d)", item.name, item.pid];
        self.navigationItem.prompt = [@"Connected: " stringByAppendingString:self.connectedProcess];
    }
    NSString *message = (kr == KERN_SUCCESS && task != MACH_PORT_NULL)
        ? [NSString stringWithFormat:@"Mach task port acquired for %@ (PID %d).", item.name, item.pid]
        : [NSString stringWithFormat:@"task_for_pid failed: %s (%d)", mach_error_string(kr), kr];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:
        (kr == KERN_SUCCESS ? @"Connected" : @"Connection failed")
        message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

'''
    if marker not in src: raise SystemExit("DOMainViewController insertion point not found")
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
    if action_marker not in src: raise SystemExit("Dopamine action menu insertion point not found")
    src = src.replace(action_marker, ",\n" + action + action_marker, 1)
    MAIN.write_text(src)

ent = ENT.read_text()
if "<key>task_for_pid-allow</key>" not in ent:
    ent = ent.replace("</dict>", "\t<key>task_for_pid-allow</key>\n\t<true/>\n\t<key>com.apple.system-task-ports</key>\n\t<true/>\n</dict>")
    ENT.write_text(ent)

info = INFO.read_text()
if "CFBundleDisplayName" not in info:
    info = info.replace("<dict>", "<dict>\n\t<key>CFBundleDisplayName</key>\n\t<string>ExternalHUD</string>", 1)
else:
    info = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>).*?(</string>)", r"\1ExternalHUD\2", info, count=1)
INFO.write_text(info)

pbx = PBX.read_text().replace("com.opa334.Dopamine", "com.gira983.ExternalHUD")
PBX.write_text(pbx)
print("ExternalHUD process manager patch applied to Dopamine 3.0.13.")
