# Compatibility Policy

## Current status

No device + iOS build combination has been validated by this repository yet. The app's baseline deployment target is iOS 14.0; this is a build target, not a claim that every iOS 14+ device or jailbreak environment is supported.

## Required compatibility key

Every future compatibility record must specify:

- ProductType / hardware identifier (for example, iPhone13,2)
- CPU architecture (arm64 or arm64e)
- iOS version range
- Exact build identifiers or an explicit tested-build set
- Required component and component version
- Test result, date, and evidence
- Known limitations

## Status values

- untested — no validation evidence; treated as unsupported.
- supported — exact configuration passed the documented test suite.
- unsupported — known incompatibility or failed validation.
- deprecated — previously supported but no longer maintained.

Do not infer compatibility from marketing device names, CPU family, or major iOS version alone.
