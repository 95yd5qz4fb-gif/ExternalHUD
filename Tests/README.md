# Tests

COMPATIBILITY_TEST_PLAN.md defines the manual compatibility matrix. The CI guard in Scripts/validate_project.py checks repository invariants and ensures the initial app-only source does not silently gain cross-process task or memory APIs.

A green CI build confirms compilation and package creation for the configured slices. It does not replace installation and runtime testing on physical devices.
