#!/usr/bin/env python3
"""CI checks for the standalone ExternalHUD IPA target and project invariants."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

makefile = (ROOT / "Makefile").read_text(encoding="utf-8")
workflow = (ROOT / ".github/workflows/build.yml").read_text(encoding="utf-8")
required_sources = [
    "HUD/EHHomeViewController.m", "HUD/EHFloatingHUDView.m",
    "System/EHDeviceInfo.m", "System/EHCompatibility.m",
    "Capabilities/EHCapabilityRegistry.m", "Diagnostics/EHDiagnostics.m",
    "Process/EHProcessManager.m",
]
for source in required_sources:
    require(source in makefile, f"Makefile does not compile required source: {source}")
    require((ROOT / source).is_file(), f"Required source is missing: {source}")

require("ARCHS := arm64 arm64e" in makefile, "Both arm64 and arm64e must remain build targets.")
require("ExternalHUD_BUNDLE_IDENTIFIER := com.gira983.externalhud" in makefile,
        "Bundle identifier is missing or changed unexpectedly.")
require("make stage FINALPACKAGE=1" in workflow, "CI must stage an iOS app, not a Debian package.")
require("Payload/ExternalHUD.app" in workflow and "ExternalHUD.ipa" in workflow,
        "CI must package the app in the standard IPA Payload layout.")
require("path: dist/ExternalHUD.ipa" in workflow, "CI must upload the IPA.")
require((ROOT / "Resources/Info.plist").is_file(), "Application Info.plist is missing.")
require('.theos/_/Applications/ExternalHUD.app' in workflow, "CI must locate Theos' staged application bundle.")
require("packages/*.deb" not in workflow, "The artifact must not be a .deb.")
require("python3 Scripts/validate_project.py" in workflow, "CI must run project validation.")
require("actions/upload-artifact@v4" in workflow, "CI must upload the IPA artifact.")

process = (ROOT / "Process/EHProcessManager.m").read_text(encoding="utf-8")
require("mach_task_self()" in process, "Self-process session implementation is missing.")
require("EHProcessSessionStatusBackendUnavailable" in process,
        "External target must report an unavailable backend rather than false success.")
require("session.target.processIdentifier != getpid()" in process,
        "Process session must reject non-self targets.")

compat = (ROOT / "System/EHCompatibility.m").read_text(encoding="utf-8")
for invariant in ("rule.testedBuilds.count == 0", "[rule.testedBuilds containsObject:buildVersion]",
                  "isValidVersionString:", "isValidBuildIdentifier:", "NSOrderedDescending",
                  "return EHCompatibilityStatusUnknown;"):
    require(invariant in compat, f"Compatibility invariant missing: {invariant}")

blocked_apis = re.compile(
    r"\b(task_for_pid|task_name_for_pid|processor_set_tasks|"
    r"vm_read_overwrite|vm_write|mach_vm_read_overwrite|mach_vm_write)\s*\("
)
source_dirs = ("Application", "HUD", "System", "Capabilities", "Diagnostics", "Process")
source_suffixes = {".m", ".mm", ".c", ".cc", ".cpp", ".h", ".hpp"}
for directory in source_dirs:
    base = ROOT / directory
    if base.exists():
        for path in base.rglob("*"):
            if path.is_file() and path.suffix in source_suffixes:
                if blocked_apis.search(path.read_text(encoding="utf-8", errors="replace")):
                    errors.append(f"Cross-process API detected: {path.relative_to(ROOT)}")

if errors:
    print("ExternalHUD validation FAILED:")
    for error in errors: print(f" - {error}")
    sys.exit(1)
print("ExternalHUD validation passed: IPA target, process-session invariants, sources, and compatibility checks.")
