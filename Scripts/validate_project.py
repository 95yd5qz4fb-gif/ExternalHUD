#!/usr/bin/env python3
from pathlib import Path
import sys
R=Path(__file__).resolve().parents[1]; errors=[]
def req(x,m):
 if not x: errors.append(m)
mk=(R/"Makefile").read_text(); wf=(R/".github/workflows/build.yml").read_text()
for p in ["HUD/EHHomeViewController.m","HUD/EHFloatingHUDView.m","System/EHDeviceInfo.m","System/EHCompatibility.m","Capabilities/EHCapabilityRegistry.m","Diagnostics/EHDiagnostics.m","Process/EHProcessManager.m"]:
 req(p in mk and (R/p).is_file(),"Missing build source: "+p)
req("ARCHS := arm64 arm64e" in mk,"arm64/arm64e targets missing")
req("make stage FINALPACKAGE=1" in wf and "ExternalHUD.ipa" in wf,"IPA workflow missing")
p=(R/"Process/EHProcessManager.m").read_text()
for s in ["proc_listpids(PROC_ALL_PIDS","proc_pidinfo(","proc_pidpath(","task_for_pid(","mach_port_deallocate"]:
 req(s in p,"Process feature missing: "+s)
for s in ["vm_read","vm_write","mach_vm_read","mach_vm_write"]:
 req(s not in p,"Unexpected memory API: "+s)
u=(R/"HUD/EHHomeViewController.m").read_text()
for s in ["RUNNING PROCESSES","reloadProcesses","connectProcess:"]:
 req(s in u,"Process UI missing: "+s)
if errors:
 print("Validation FAILED");[print(" - "+e) for e in errors];sys.exit(1)
print("Validation passed: process enumeration, Mach task-port request, and IPA package.")
