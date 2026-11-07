# ExternalHUD authorized target integration contract

## Purpose

This document defines the supported integration boundary for a companion app that the developer owns or is authorized to instrument. ExternalHUD itself does not obtain arbitrary task ports or inspect another app's private memory.

## Target-side agent

A companion target must explicitly embed a target-side agent and expose only documented diagnostic operations. The target owns its data and decides which operations are available. A target that does not embed the agent is not attachable through this interface.

## Required handshake

1. The target starts its agent while the target app is in the foreground.
2. The user explicitly enables a debug session in the target app.
3. The target creates a fresh random session nonce and displays or transfers it through a user-approved pairing flow.
4. ExternalHUD connects to the target agent and sends a protocol-version request plus the nonce.
5. The target validates the nonce, protocol version, and user-enabled session state.
6. The target returns a capability list. Unknown capabilities are rejected.
7. Every command is scoped to the target agent's public API; no raw task port or arbitrary address read/write exists.
8. The target closes the session when the user disables debugging, the app backgrounds, or the nonce expires.

## Minimum protocol operations

- hello: protocol version and nonce validation.
- get_info: app version, bundle identifier, target build, and supported diagnostic schema.
- get_metrics: explicitly exported app-owned counters and performance measurements.
- ping: round-trip and connection-health measurement.
- close: terminate the session and clear transient credentials.

## Security properties

- Pairing is explicit and time-limited.
- Nonces are single-use and expire.
- Commands use an allowlist.
- No filesystem traversal, arbitrary code execution, task-port export, or raw memory access.
- A successful handshake means only that the authorized agent accepted the session; it does not imply kernel privileges.

## iOS platform constraints

A normal iOS app cannot display a system-wide floating window over unrelated apps. The current HUD is in-app. A device-wide overlay requires a separate supported platform integration and must not be represented as available in this IPA.
