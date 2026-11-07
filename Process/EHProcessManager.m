#import "EHProcessManager.h"
#import <libproc.h>
#import <mach/mach.h>
#import <unistd.h>
#import <sys/proc.h>
#import <sys/types.h>
@interface EHProcessTarget ()
@property(nonatomic,assign,readwrite) pid_t processIdentifier;
@property(nonatomic,copy,readwrite) NSString *processName;
@property(nonatomic,copy,readwrite) NSString *bundleIdentifier;
@property(nonatomic,copy,readwrite) NSString *executablePath;
@property(nonatomic,assign,readwrite,getter=isCurrentProcess) BOOL currentProcess;
@end
@implementation EHProcessTarget @end
@interface EHProcessSession ()
@property(nonatomic,strong,readwrite) EHProcessTarget *target;
@property(nonatomic,assign,readwrite) EHProcessSessionStatus status;
@property(nonatomic,copy,readwrite) NSString *detail;
@property(nonatomic,assign,readwrite) mach_port_t taskPort;
@end
@implementation EHProcessSession
- (void)dealloc { if (_taskPort!=MACH_PORT_NULL) mach_port_deallocate(mach_task_self(),_taskPort); }
@end
@implementation EHProcessManager
+ (NSString *)bundleIdentifierForPath:(NSString *)path {
 if (!path.length) return @"—";
 NSRange r=[path rangeOfString:@".app/" options:NSBackwardsSearch];
 if (r.location==NSNotFound) return @"—";
 NSBundle *b=[NSBundle bundleWithPath:[path substringToIndex:r.location+4]];
 return b.bundleIdentifier ?: @"—";
}
+ (EHProcessTarget *)makeTarget:(pid_t)pid name:(NSString *)name path:(NSString *)path {
 EHProcessTarget *t=[EHProcessTarget new]; t.processIdentifier=pid;
 t.processName=name.length?name:[NSString stringWithFormat:@"pid-%d",pid];
 t.executablePath=path?:@""; t.bundleIdentifier=[self bundleIdentifierForPath:path];
 t.currentProcess=(pid==getpid()); return t;
}
+ (EHProcessTarget *)currentProcess {
 char p[PROC_PIDPATHINFO_MAXSIZE]={0}; proc_pidpath(getpid(),p,sizeof(p));
 return [self makeTarget:getpid() name:NSProcessInfo.processInfo.processName path:(p[0]?[NSString stringWithUTF8String:p]:@"")];
}
+ (NSArray<EHProcessTarget *> *)allProcesses {
 int bytes=proc_listpids(PROC_ALL_PIDS,0,NULL,0); if(bytes<=0)return @[];
 size_t cap=(size_t)bytes+sizeof(pid_t)*32; pid_t *pids=calloc(1,cap); if(!pids)return @[];
 int used=proc_listpids(PROC_ALL_PIDS,0,pids,(int)cap);
 NSMutableArray *out=[NSMutableArray array];
 if(used>0) for(size_t i=0;i<(size_t)used/sizeof(pid_t);i++) {
  pid_t pid=pids[i]; if(pid<=0)continue;
  struct proc_bsdinfo info={0};
  if(proc_pidinfo(pid,PROC_PIDTBSDINFO,0,&info,sizeof(info))!=sizeof(info))continue;
  char path[PROC_PIDPATHINFO_MAXSIZE]={0}; proc_pidpath(pid,path,sizeof(path));
  NSString *name=info.pbi_name[0]?[NSString stringWithUTF8String:info.pbi_name]:[NSString stringWithFormat:@"pid-%d",pid];
  NSString *exe=path[0]?[NSString stringWithUTF8String:path]:@"";
  [out addObject:[self makeTarget:pid name:name path:exe]];
 }
 free(pids);
 [out sortUsingComparator:^NSComparisonResult(EHProcessTarget *a,EHProcessTarget *b){return [a.processName localizedCaseInsensitiveCompare:b.processName];}];
 return out;
}
+ (EHProcessTarget *)targetForPID:(pid_t)pid {
 for(EHProcessTarget *t in [self allProcesses]) if(t.processIdentifier==pid)return t;
 return nil;
}
+ (EHProcessSession *)attachToTarget:(EHProcessTarget *)target {
 EHProcessSession *s=[EHProcessSession new]; s.target=target; s.taskPort=MACH_PORT_NULL;
 if(!target||target.processIdentifier<=0){s.status=EHProcessSessionStatusRejected;s.detail=@"Invalid PID.";return s;}
 if(kill(target.processIdentifier,0)!=0){s.status=EHProcessSessionStatusProcessExited;s.detail=@"Process exited or is not visible.";return s;}
 if(target.processIdentifier==getpid()){
  s.taskPort=mach_task_self(); mach_port_mod_refs(mach_task_self(),s.taskPort,MACH_PORT_RIGHT_SEND,1);
  s.status=EHProcessSessionStatusAttachedToSelf;s.detail=@"Connected to own task port.";return s;
 }
 mach_port_t port=MACH_PORT_NULL; kern_return_t kr=task_for_pid(mach_task_self(),target.processIdentifier,&port);
 if(kr==KERN_SUCCESS&&port!=MACH_PORT_NULL){s.taskPort=port;s.status=EHProcessSessionStatusAttached;s.detail=@"Mach task port acquired. No memory operations are performed.";}
 else {s.status=(kr==KERN_FAILURE||kr==KERN_INVALID_ARGUMENT)?EHProcessSessionStatusPermissionDenied:EHProcessSessionStatusRejected;
 s.detail=[NSString stringWithFormat:@"task_for_pid failed: kern_return_t=%d (%s).",kr,mach_error_string(kr)];}
 return s;
}
+ (NSString *)displayNameForStatus:(EHProcessSessionStatus)status {
 switch(status){
 case EHProcessSessionStatusDetached:return @"DETACHED";
 case EHProcessSessionStatusAttachedToSelf:return @"CONNECTED · SELF";
 case EHProcessSessionStatusAttached:return @"CONNECTED";
 case EHProcessSessionStatusPermissionDenied:return @"PERMISSION DENIED";
 case EHProcessSessionStatusProcessExited:return @"PROCESS EXITED";
 case EHProcessSessionStatusRejected:return @"REJECTED";
 } return @"UNKNOWN";
}
@end
