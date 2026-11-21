# src/shared

Visible to both server and client (it becomes `ReplicatedStorage.Shared`). Nothing secret goes here.

- `LiveFlags.luau`: the live on/off switches. Read a switch with `LiveFlags.isOn("name")`.
- Add as the game grows: `Config.luau` (tuning numbers), `Catalog.luau` (items with stable ids), `Remotes.luau` (the one list of remotes), `Guard.luau` (argument checks), `Types.luau`. Templates are in the `luau-conventions` and `remote-security-checklist` skills.
