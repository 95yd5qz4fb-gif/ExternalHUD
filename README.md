# ExternalHUD

ExternalHUD is an experimental, device-aware iOS HUD and diagnostics application built with Objective-C and Theos.

## Project goals

- Provide an in-app floating HUD and configurable diagnostics menu.
- Detect device model, CPU architecture, OS version, and build number.
- Maintain a declarative compatibility catalog for optional system components.
- Keep Kernel, PAC, and PPL capability metadata separate from the UI and diagnostics layers.
- Prefer public APIs and explicit capability checks; fail closed when a capability is unavailable or unknown.

## Current implementation status

This repository starts with the application shell, environment detection, compatibility metadata, and local diagnostics. The initial release does not execute kernel exploits, implement PAC/PPL bypasses, acquire task ports for unrelated processes, or read/write memory in other processes. Diagnostics are limited to the app itself and explicitly authorized test targets.

## Architecture

- `Application/` — UIKit application lifecycle and root screen.
- `HUD/` — in-app floating panel and menu components.
- `System/` — device/OS detection and compatibility model.
- `Capabilities/` — descriptive Kernel/PAC/PPL capability registry; no exploit payload execution.
- `Diagnostics/` — app-local runtime diagnostics.
- `Resources/` — app metadata and assets.

## Build

Requires macOS, Xcode command-line tools, and Theos with an iPhoneOS SDK.

```sh
make package FINALPACKAGE=1
```

The initial target is arm64/arm64e and iOS 14.0+. The actual deployment range will be refined after compiling and testing against the supported SDKs and devices.

## Security and compatibility principles

1. Unknown device/build combinations are unsupported by default.
2. Compatibility entries must identify exact version/build ranges and architecture constraints.
3. Never infer a successful capability from device model alone.
4. Keep diagnostics read-only and scoped to this application unless a test target is explicitly configured.
5. Do not silently fall back to private APIs or weaker security checks.

## License

TBD. Do not redistribute third-party exploit code or binaries through this repository.
