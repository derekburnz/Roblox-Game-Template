# src/shared

Visible to both server and client (it becomes `ReplicatedStorage.Shared`). Nothing secret goes here.

- `LiveFlags.luau`: the live on/off switches. Read a switch with `LiveFlags.isOn("name")`.
- `Remotes.luau`: the one list of remotes, each with its arguments and what the server checks.
- `SaveSchema.luau`: what a save holds, its `VERSION` and the migrations. Read its header before adding a field.
- `TelemetryRules.luau`, `RestartNotice.luau`: the pure rules behind `Telemetry` and the restart countdown.
- `Guard.luau`: argument checks for remotes (`Guard.id`, `Guard.int`, `Guard.oneOf`, `Guard.text`...), each returning the cleaned value or nil.
- `Signal.luau`: a small typed signal (`DataService.onLoaded` uses it).
- Add as the game grows: `Config.luau` (tuning numbers), `Catalog.luau` (items with stable ids) and `Types.luau`. Templates are in the `luau-conventions` and `remote-security-checklist` skills.

Keep game rules here (or in `server/Util/`) as pure modules with no Roblox services at load time, so `tests/specs` can cover them.
