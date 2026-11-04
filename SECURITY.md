# Security Model

## Scope

ExternalHUD's initial implementation is an application-local HUD and diagnostics shell. It does not contain kernel exploit payloads, PAC/PPL bypass implementations, arbitrary task-port acquisition, or cross-process memory access.

## Required invariants

- **Fail closed:** an unknown device, OS version, build, or architecture is not considered compatible.
- **Exact matching:** compatibility requires an exact hardware identifier, binary slice, OS range, and tested build identifier.
- **No optimistic capability claims:** a device model alone cannot establish that a kernel, PAC, or PPL capability is available.
- **Least privilege:** diagnostics are scoped to the current process.
- **No silent fallback:** unavailable APIs or failed checks must be surfaced as unavailable, not bypassed.
- **No remote configuration execution:** compatibility metadata is data only and must never be interpreted as executable code.
- **No embedded secrets:** signing credentials, tokens, and private keys must never be committed.
- **No cross-process primitives in the initial app:** CI checks for task-port acquisition and cross-process VM read/write APIs.

## CI validation

Scripts/validate_project.py verifies required source inclusion, package metadata, architecture targets, exact-build compatibility checks, artifact upload configuration, and the initial app-only API boundary.

## Review checklist for future changes

1. Confirm all inputs are validated and bounded.
2. Check integer conversions, allocation sizes, and ownership/lifetime.
3. Check API availability against the declared deployment target.
4. Test arm64 and arm64e builds separately where possible.
5. Verify unknown device/build combinations remain unsupported.
6. Keep diagnostics read-only and process-local.
7. Review dependency provenance, license, pinned version, and update history.
8. Add a regression test for every compatibility rule.
9. Separate compile success from physical-device runtime validation.

## Reporting

Do not publish device identifiers, crash logs, or diagnostic snapshots that contain personal data without reviewing and redacting them first.
