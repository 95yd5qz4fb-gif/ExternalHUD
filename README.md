# ExternalHUD
Standalone iOS process manager distributed as an IPA.

- Enumerates visible processes using libproc.
- Displays PID, process name, bundle identifier when available, and executable path in the connection result.
- Selecting a process requests a Mach task port through task_for_pid.
- Reports Mach return codes when access is denied.
- Holds an acquired task port for the session and deallocates it when the session is released.
- Does not read or write process memory, inject code, or execute remote commands.

Process visibility and task-port access depend on iOS version, jailbreak state, and application entitlements. A visible PID does not guarantee task_for_pid success. CI verifies compilation and packaging, not device-side permission.
