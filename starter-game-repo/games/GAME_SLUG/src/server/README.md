# src/server

Runs on Roblox's server only (it becomes `ServerScriptService.Server`). Players cannot read or change it.

- `Main.server.luau` loads every module in `Services/`.
- `Services/<Name>Service.luau`: one system per file, with `Init(services)` and `Start()`.
- `Vendor/`: third-party single-file modules (for example a save library). Never edit or reformat them.

Rule: the server decides every outcome. See the `remote-security-checklist` skill before writing a remote handler.
