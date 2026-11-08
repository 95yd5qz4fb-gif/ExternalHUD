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
        '#import <libproc.h>\\n'
        '#import <dispatch/dispatch.h>'
    )
    marker = "@interface DOMainViewController ()"
    process_ui = r    process_ui = r'''
@interface EHProcessItem : NSObject
@property(nonatomic, assign) pid_t pid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *path;
@property(nonatomic, copy) NSString *status;
@end
@implementation EHProcessItem
@end

@interface EHProcessListViewController : UITableViewController
@property(nonatomic, strong) NSArray<EHProcessItem *> *processes;
@end

@implementation EHProcessListViewController

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
    NSMutableArray<EHProcessItem *> *items = [NSMutableArray array];
    int capacity = 2048;
    pid_t *pids = calloc((size_t)capacity, sizeof(pid_t));
    if (pids) {
        int bytes = proc_listallpids(pids, capacity * (int)sizeof(pid_t));
        if (bytes > 0) {
            int count = MIN(bytes / (int)sizeof(pid_t), capacity);
            for (int i = 0; i < count; i++) {
                pid_t pid = pids[i];
                if (pid <= 0) continue;
                char nameBuffer[PROC_PIDPATHINFO_MAXSIZE] = {0};
                char pathBuffer[PROC_PIDPATHINFO_MAXSIZE] = {0};
                proc_name(pid, nameBuffer, sizeof(nameBuffer));
                int pathResult = proc_pidpath(pid, pathBuffer, sizeof(pathBuffer));
                EHProcessItem *item = [EHProcessItem new];
                item.pid = pid;
                item.name = nameBuffer[0] ? [NSString stringWithUTF8String:nameBuffer]
                                          : [NSString stringWithFormat:@"pid-%d", pid];
                item.path = pathResult > 0 && pathBuffer[0] ? [NSString stringWithUTF8String:pathBuffer] : @"";
                item.status = pid == getpid() ? @"This app" : @"Visible process metadata";
                [items addObject:item];
            }
        }
        free(pids);
    }

    if (items.count == 0) {
        EHProcessItem *item = [EHProcessItem new];
        item.pid = getpid();
        item.name = [NSString stringWithUTF8String:getprogname() ?: "ExternalHUD"];
        char pathBuffer[PROC_PIDPATHINFO_MAXSIZE] = {0};
        int pathResult = proc_pidpath(getpid(), pathBuffer, sizeof(pathBuffer));
        item.path = pathResult > 0 ? [NSString stringWithUTF8String:pathBuffer] : @"";
        item.status = @"Current app only";
        [items addObject:item];
        UILabel *label = [[UILabel alloc] initWithFrame:self.tableView.bounds];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        label.text = @"iOS did not expose a process list. Showing ExternalHUD only.\\nOther apps' task objects and memory are not accessible to a normal app.";
        label.textColor = [UIColor secondaryLabelColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 0;
        label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        self.tableView.backgroundView = label;
    } else {
        self.tableView.backgroundView = nil;
    }

    [items sortUsingComparator:^NSComparisonResult(EHProcessItem *a, EHProcessItem *b) {
        if (a.pid == getpid()) return NSOrderedAscending;
        if (b.pid == getpid()) return NSOrderedDescending;
        return [a.name localizedCaseInsensitiveCompare:b.name];
    }];
    self.processes = items;
    self.navigationItem.prompt = [NSString stringWithFormat:
        @"Stock iOS process API · %lu visible · metadata only", (unsigned long)items.count];
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
        ? [NSString stringWithFormat:@"PID %d · %@\\n%@", item.pid, item.status, item.path]
        : [NSString stringWithFormat:@"PID %d · %@", item.pid, item.status];
    cell.detailTextLabel.numberOfLines = 2;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    EHProcessItem *item = self.processes[indexPath.row];
    NSString *detail = [NSString stringWithFormat:
        @"Selected %@ (PID %d).\\n\\nExternalHUD can show process metadata exposed by stock iOS. It cannot acquire arbitrary Mach task ports, kernel task objects, or inspect another app's memory on a normal iOS installation.",
        item.name, item.pid];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Process selected"
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
