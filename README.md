# ExternalHUD

Standalone iOS process manager based on the Dopamine 3.0.13 jailbreak codebase.

- Dopamine is pinned as a Git submodule at commit 5b1d2c1c3bf54dd8e3641d29c60cd3a0c13cde88 (tag 3.0.13).
- The app retains Dopamine's jailbreak bootstrap and adds a local process browser.
- Selecting a process requests and retains its Mach task port; this app does not read/write target memory or inject code.
- No remote server or separate companion app is used.
- Initial target: iPhone 12 (A14), iOS 16.7.12.

GitHub Actions builds and uploads ExternalHUD.ipa. Dopamine license and attribution are retained in the submodule.
