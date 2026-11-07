# ExternalHUD

ExternalHUD is a standalone iOS application built with Objective-C and Theos. The distributable build is an IPA intended for installation as an app (for example, through TrollStore on supported devices), not a jailbreak tweak package.

## Product direction

- Standalone app with a floating HUD and configurable menu.
- Device, architecture, iOS version, and exact build detection.
- Process-integration architecture with explicit capability and compatibility reporting.
- Separate capability layers for kernel primitives, PAC, and PPL.
- Clear distinction between detected, tested, supported, and unavailable capabilities.

## Current implementation status

The current source contains the UIKit app shell, in-app HUD, device/environment detection, compatibility evaluator, descriptive capability registry, and app-local diagnostics. It does not yet contain a working process attachment backend or executable kernel exploit modules. The current build is an IPA shell; a green CI build proves compilation and packaging, not that process integration works on a physical device.

## Architecture

- Application/ — UIKit application lifecycle.
- HUD/ — floating panel and menu UI.
- System/ — device/OS detection and compatibility evaluation.
- Capabilities/ — capability catalog and status model.
- Diagnostics/ — local diagnostics.
- Tests/ — compatibility test plan.
- Scripts/ — CI validation.

## Build

Requires macOS, Xcode command-line tools, and Theos with an iPhoneOS SDK.

    make stage FINALPACKAGE=1

The GitHub Actions workflow stages the app, wraps it in the standard Payload/ExternalHUD.app layout, and uploads ExternalHUD.ipa. The IPA is not code-signed by this workflow; installation/signing behavior depends on the installation method and target device.

## Compatibility principles

1. Unknown device/build combinations remain untested.
2. Compatibility requires exact hardware, architecture, OS range, and tested build matching.
3. Kernel, PAC, and PPL are distinct capability layers.
4. Metadata must not be presented as proof that an exploit or primitive works.
5. CI success is not a substitute for on-device runtime testing.

## Process integration

The intended product direction includes process discovery and integration. The current repository does not yet implement a functioning arbitrary-process attachment backend. Any future backend must have a separately defined authorization model, compatibility matrix, and device test plan; the UI must not claim attachment success based only on device metadata.

## License

TBD. Third-party exploit code or binaries are not bundled by this repository.
