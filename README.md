# ExternalHUD

ExternalHUD is a standalone iOS application. GitHub Actions produces an **IPA** (standard Payload/ExternalHUD.app layout), not a tweak package.

## Current app modules

- UIKit application shell and draggable floating HUD.
- Device, OS, build, and binary-slice detection.
- Fail-closed compatibility evaluator.
- Capability catalog with distinct Kernel, KFD, DarkSword, PAC, and PPL entries.
- Local diagnostics.
- Process session manager with an explicitly self-only first backend.

## Process integration status

The Process Center currently creates and validates a session for ExternalHUD's own process. It does **not** enumerate or attach to other apps. External-process discovery and a kernel-backed attachment backend remain unimplemented; the UI reports this as unavailable rather than pretending a connection succeeded. The process manager is separated from the UI so a future, independently validated backend can be added without rewriting the HUD.

## Build

Requires macOS, Xcode command-line tools, Theos, and an iPhoneOS SDK.

    make stage FINALPACKAGE=1

GitHub Actions stages the app, packages `Payload/ExternalHUD.app` into `ExternalHUD.ipa`, and uploads the IPA artifact. The workflow does not sign the IPA. Installation/signing depends on the target device and installation method.

## Compatibility

Unknown device/build combinations remain untested. A compatibility result requires exact hardware identifier, binary slice, supported OS range, and exact tested build membership. CI success proves compile/package only, not runtime support on physical devices.

## Security and correctness

- No kernel exploit payloads or PAC/PPL bypass code are bundled.
- No arbitrary task-port acquisition or cross-process memory operations are performed.
- A process session is never reported as attached unless the current app's own task is the target.
- Capability metadata is descriptive and is not proof of a working backend.
