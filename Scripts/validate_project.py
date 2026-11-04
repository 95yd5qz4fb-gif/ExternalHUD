#!/usr/bin/env python3
"""Fast CI guard for ExternalHUD's initial app-only security/compatibility scope."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

makefile = (ROOT / "Makefile").read_text(encoding="utf-8")
control_text = (ROOT / "control").read_text(encoding="utf-8")
workflow = (ROOT / ".github/workflows/build.yml").read_text(encoding="utf-8")

required_sources = [
    "HUD/EHHomeViewController.m",
    "HUD/EHFloatingHUDView.m",
    "System/EHDeviceInfo.m",
    "System/EHCompatibility.m",
    "Capabilities/EHCapabilityRegistry.m",
    "Diagnostics/EHDiagnostics.m",
]
for source in required_sources:
    require(source in makefile, f"Makefile does not compile required source: {source}")
    require((ROOT / source).is_file(), f"Required source is missing: {source}")

require("ARCHS := arm64 arm64e" in makefile, "Both arm64 and arm64e must remain build targets.")
require("ExternalHUD_BUNDLE_IDENTIFIER := com.gira983.externalhud" in makefile,
        "Bundle identifier is missing or changed unexpectedly.")

control = {}
for line in control_text.splitlines():
    if ":" in line:
        key, value = line.split(":", 1)
        control[key.strip()] = value.strip()
for key in ("Package", "Name", "Version", "Architecture"):
    require(bool(control.get(key)), f"Debian control field is missing: {key}")
require(control.get("Package") == "com.gira983.externalhud",
        "Debian package identifier must match the app bundle identifier.")
require(control.get("Architecture") == "iphoneos-arm64",
        "Unexpected Debian package architecture.")

require("python3 Scripts/validate_project.py" in workflow,
        "CI must run the project invariant checks.")
require("actions/upload-artifact@v4" in workflow and "packages/*.deb" in workflow,
        "CI must upload the generated Debian package.")

compat = (ROOT / "System/EHCompatibility.m").read_text(encoding="utf-8")
require("rule.testedBuilds.count == 0" in compat,
        "Compatibility rules must require a non-empty tested-build set.")
require("[rule.testedBuilds containsObject:buildVersion]" in compat,
        "Compatibility evaluation must require an exact build match.")
require("return EHCompatibilityStatusUnknown;" in compat,
        "Unknown compatibility must fail closed.")

# Initial product scope: no cross-process task acquisition or VM read/write APIs.
blocked_apis = re.compile(
    r"\b(task_for_pid|task_name_for_pid|processor_set_tasks|"
    r"vm_read_overwrite|vm_write|mach_vm_read_overwrite|mach_vm_write)\s*\("
)
source_dirs = ("Application", "HUD", "System", "Capabilities", "Diagnostics")
source_suffixes = {".m", ".mm", ".c", ".cc", ".cpp", ".h", ".hpp"}
for directory in source_dirs:
    base = ROOT / directory
    if not base.exists():
        continue
    for path in base.rglob("*"):
        if path.is_file() and path.suffix in source_suffixes:
            source = path.read_text(encoding="utf-8", errors="replace")
            if blocked_apis.search(source):
                errors.append(f"Cross-process API detected: {path.relative_to(ROOT)}")

if errors:
    print("ExternalHUD validation FAILED:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print("ExternalHUD validation passed: source layout, package metadata, build slices, and fail-closed compatibility checks.")
