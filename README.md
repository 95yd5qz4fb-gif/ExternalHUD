# ExternalHUD

Standalone iOS application. CI packages the app as an **IPA** using the standard `Payload/ExternalHUD.app` structure.

## Modules currently present

- UIKit app shell and draggable floating HUD.
- Device, OS, build, and binary-slice detection.
- Fail-closed compatibility evaluator.
- Kernel/KFD/DarkSword/PAC/PPL capability catalog.
- Local diagnostics.
- Process session manager; the currently implemented backend is self-process only.

## Process integration status

The Process Center currently creates a session for ExternalHUD's own process. It does not enumerate or attach to other apps. External-process discovery and a kernel-backed attachment backend are not implemented yet. The UI reports this honestly instead of claiming a successful connection. The manager is isolated from the UI so an authorized, validated backend can be integrated separately.

## Build and artifact

The GitHub Actions workflow runs `make stage FINALPACKAGE=1`, verifies the staged app's Info.plist and bundle identifier, packages `Payload/ExternalHUD.app` into `ExternalHUD.ipa`, checks the ZIP archive, and uploads the IPA. The workflow does not sign the app.

## Compatibility

Unknown device/build combinations remain untested. A compatibility result requires exact hardware identifier, binary slice, supported OS range, and exact tested build membership. CI success proves compilation and packaging, not physical-device runtime support.

## Security and correctness

- No kernel exploit payloads or PAC/PPL bypass code are bundled.
- No arbitrary task-port acquisition or cross-process memory operations are performed.
- A session is reported as attached only for ExternalHUD's own process.
- Capability metadata is descriptive, not proof of a working backend.

## Public CI

This repository is public. The IPA workflow uses public GitHub Actions and does not require a repository secret for the current unsigned build.
