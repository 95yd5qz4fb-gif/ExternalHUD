# Compatibility evaluator test plan

The evaluator is deliberately fail-closed. No production rule is currently registered, so all devices report **UNTESTED**.

| Case | Input difference | Expected result |
|---|---|---|
| No rules | Empty rule list | Unknown / UNTESTED |
| Exact match | ProductType, binary slice, OS range, and exact build all match | Rule status |
| Wrong device | ProductType differs | Unknown |
| Wrong binary slice | arm64 vs arm64e differs | Unknown |
| Wrong build | Build ID is not in testedBuilds | Unknown |
| OS below range | OS version is below minimum | Unknown |
| OS above range | OS version is above maximum | Unknown |
| Incomplete rule | Empty model, architecture, version bound, or build set | Rule ignored |
| Conflicting rules | Two matching records report different statuses | Unknown |

## Device validation matrix

Before marking a configuration supported, record the exact hardware identifier, binary slice, iOS version, build identifier, test date, app commit, launch result, HUD drag/expand result, background/foreground result, and local diagnostics result.

A successful compile is not a device-runtime test. Never change an entry to supported solely because GitHub Actions passed.
